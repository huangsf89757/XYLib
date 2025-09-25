//
//  XYGroupNode.swift
//  Pods
//
//  Created by hsf on 2025/9/17.
//

import Foundation
import XYLog

// MARK: - XYGroupNode
/// 单个子命令在组内的结构化结果，避免直接暴露 Any?
public struct XYGroupResult {
    public let index: Int
    public let id: String
    public let value: Any?
    public let error: XYError?

    public var isSuccess: Bool { error == nil }
}

open class XYGroupNode: XYNode<[XYGroupResult]> {
    
    // MARK: var
    /// 子命令列表
    public let executables: [any XYExecutable]
    /// 执行模式
    public let mode: ExecutionMode
    /// 是否允许部分失败（true = 部分失败仍继续，false = 任一失败立即停止）
    public let allowPartialFailure: Bool
    
    
    // Actor to serialize access to internal mutable state and avoid races in concurrent execution.
    private actor GroupState {
        enum ChildResult {
            case success(Any?)
            case failure(XYError)
        }
        
        var collectedErrors: [XYError] = []
        var childResults: [ChildResult?]
        var completedCount: Int = 0
        
        init(count: Int) {
            self.childResults = Array(repeating: nil, count: count)
        }
        
        func setChildResult(_ result: ChildResult, at index: Int) {
            guard index >= 0 && index < childResults.count else { return }
            childResults[index] = result
            completedCount += 1
        }
        
        func appendError(_ error: XYError) {
            collectedErrors.append(error)
        }
        
        func appendErrors(_ errors: [XYError]) {
            collectedErrors.append(contentsOf: errors)
        }
        
        func snapshot() -> (childResults: [ChildResult?], collectedErrors: [XYError], completedCount: Int) {
            return (childResults, collectedErrors, completedCount)
        }
        
        func firstError() -> XYError? {
            return collectedErrors.first
        }
    }
    
    // State manager instance (created per run)
    private var internalState: GroupState?

    /// 返回当前组（如果存在）的错误快照（async 安全）
    public func getCollectedErrors() async -> [XYError] {
        if let st = internalState {
            return (await st.snapshot()).collectedErrors
        }
        return []
    }

    /// 返回当前组每个子命令的结果快照（结构化，async 安全）
    public func getResultsSnapshot() async -> [XYGroupResult] {
        if let st = internalState {
            let snap = await st.snapshot()
            return snap.childResults.enumerated().map { idx, cr in
                switch cr {
                case .success(let v)?:
                    return XYGroupResult(index: idx, id: executables[idx].id, value: v, error: nil)
                case .failure(let e)?:
                    return XYGroupResult(index: idx, id: executables[idx].id, value: nil, error: e)
                case nil:
                    let err = XYError.other(NSError(domain: "XYWorkflow", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not executed or unknown"]))
                    return XYGroupResult(index: idx, id: executables[idx].id, value: nil, error: err)
                }
            }
        }
        return executables.enumerated().map { idx, cmd in
            let err = XYError.other(NSError(domain: "XYWorkflow", code: 0, userInfo: [NSLocalizedDescriptionKey: "No state available"]))
            return XYGroupResult(index: idx, id: cmd.id, value: nil, error: err)
        }
    }
    
    
    // MARK: init
    public init(
        id: String = UUID().uuidString,
        timeout: TimeInterval = 0,
        executables: [any XYExecutable],
        mode: ExecutionMode = .concurrent,
        allowPartialFailure: Bool = false
    ) {
        self.executables = executables
        self.mode = mode
        self.allowPartialFailure = allowPartialFailure
        super.init(id: id, timeout: timeout)
        self.logTag = "WorkFlow.Node.Group"
    }
    
    public convenience init(id: String = UUID().uuidString,
                            timeout: TimeInterval = 30,
                            cmds: [XYBaseNode<Any>],
                            mode: ExecutionMode = .concurrent,
                            allowPartialFailure: Bool = false) {
        self.init(id: id, timeout: timeout, executables: cmds, mode: mode, allowPartialFailure: allowPartialFailure)
    }
    
    public convenience init(id: String = UUID().uuidString,
                            timeout: TimeInterval = 0,
                            groups: [XYGroupNode],
                            mode: ExecutionMode = .concurrent,
                            allowPartialFailure: Bool = false) {
        self.init(id: id, timeout: timeout, executables: groups, mode: mode, allowPartialFailure: allowPartialFailure)
    }
    
    public convenience init(id: String = UUID().uuidString,
                            timeout: TimeInterval = 0,
                            cmdsAndGroups: [any XYExecutable],
                            mode: ExecutionMode = .concurrent,
                            allowPartialFailure: Bool = false) {
        self.init(id: id, timeout: timeout, executables: cmdsAndGroups, mode: mode, allowPartialFailure: allowPartialFailure)
    }
    
    
    // MARK: override
    @discardableResult
    public override func run() async throws -> ResultType {
        let tag = [logTag, "execute"]
        XYLog.info(tag: tag, process: .begin, content: "id=\(id), mode=\(mode), count=\(executables.count)")
        internalState = GroupState(count: executables.count)
        startTimeoutTask()

        do {
            if mode == .concurrent {
                try await executeConcurrently()
            } else {
                try await executeSequentially()
            }

            // 如果不允许部分失败且有错误，抛出第一个错误
            if let st = internalState {
                if let firstErr = await st.firstError(), !allowPartialFailure {
                    await finishExecution()
                    throw firstErr
                }
                // 使用结构化快照返回每个子命令的结果
                let results = await getResultsSnapshot()
                await finishExecution()
                return results
            }

            await finishExecution()
            let results = await getResultsSnapshot()
            return results
        } catch {
            await finishExecution()
            if state == .cancelled {
                throw XYError.cancelled
            } else {
                throw error
            }
        }
    }
    
    public override func cancel() {
        super.cancel()
        for cmd in executables {
            cmd.cancel()
        }
    }
    
    /// 重写startTimeoutTask方法以处理超时
    internal override func startTimeoutTask() {
        guard timeout > 0 else { return }
        let tag = [logTag, "timeout"]
        // Cancel previous timeout if any
        timeoutTask?.cancel()
        let task = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                guard let self = self else { return }
                XYLog.info(tag: tag, content: "did", "id=\(self.id)")
                // 超时时设置状态为失败
                self.state = .failed
                // 取消所有子命令
                for cmd in self.executables {
                    cmd.cancel()
                }
            } catch {
                // Task was cancelled; nothing to do
            }
        }
        timeoutTask = task
        XYLog.info(tag: tag, content: "start", "id=\(id)", "\(timeout)s")
    }
}

// MARK: - ExecutionMode
extension XYGroupNode {
    public enum ExecutionMode {
        case concurrent  // 并行执行
        case sequential  // 串行执行
    }
}


// MARK: - Private Execution
private extension XYGroupNode {
    
    func executeConcurrently() async throws {
        let tag = [logTag, "concurrent"]
        XYLog.info(tag: tag, content: "start", "id=\(id)")
        
        try await withThrowingTaskGroup(of: (Int, Result<Any?, Error>).self) { group in
            for (index, cmd) in executables.enumerated() {
                group.addTask {
                    do {
                        let result = try await cmd.execute()
                        return (index, .success(result))
                    } catch let error {
                        return (index, .failure(error))
                    }
                }
            }
            
            for try await (index, result) in group {
                // 使用 actor 来处理结果与收集错误，避免竞态
                await handleCommandResult(at: index, result: result)

                // 如果不允许部分失败且已有失败，取消剩余
                if !allowPartialFailure {
                    if let st = internalState {
                        let snap = await st.snapshot()
                        if !snap.collectedErrors.isEmpty {
                            group.cancelAll()
                            break
                        }
                    }
                }
            }
        }
    }
    
    func executeSequentially() async throws {
        let tag = [logTag, "sequential"]
        XYLog.info(tag: tag, content: "start", "id=\(id)")
        
        for (index, cmd) in executables.enumerated() {
            do {
                let result = try await cmd.execute()
                await handleCommandResult(at: index, result: .success(result))
            } catch let error {
                await handleCommandResult(at: index, result: .failure(error))
                if !allowPartialFailure {
                    throw error // 立即中断
                }
            }
        }
    }
    
    func handleCommandResult(at index: Int, result: Result<Any?, Error>) async {
        guard index < executables.count else { return }
        let childCmd = executables[index]

        switch result {
        case .success(let value):
            // 更新 actor 内部状态
            if let st = internalState {
                await st.setChildResult(.success(value), at: index)
            }
            XYLog.debug(
                tag: [logTag, "child"],
                process: .succ,
                content: "id=\\(id)", "childId=\\(executables[index].id)", "result=\\(String(describing: value))"
            )

        case .failure(let error):
            let cmdError: XYError = (error as? XYError) ?? .unknown(error)

            // 更新 actor 内部状态与收集错误
            if let st = internalState {
                await st.setChildResult(.failure(cmdError), at: index)
                await st.appendError(cmdError)
            }

            // 收集子组的具体错误信息（若有且子组已失败）
            if let subGroup = executables[index] as? XYGroupNode {
                // 通过 async API 安全获取子组错误快照（不要依赖子组的 state，因为 state 是非 actor 属性）
                let subErrors = await subGroup.getCollectedErrors()
                if !subErrors.isEmpty {
                    if let st = internalState { await st.appendErrors(subErrors) }
                } else {
                    let contextError = NSError(domain: "XYWorkflow", code: 0, userInfo: [NSLocalizedDescriptionKey: "SubGroup \(subGroup.id) failed without specific error"])
                    let xErr = XYError.other(contextError)
                    if let st = internalState { await st.appendError(xErr) }
                }
            }

            XYLog.info(
                tag: [logTag, "child"],
                process: .fail(cmdError.info),
                content: "id=\\(id)", "childId=\\(executables[index].id)"
            )
        }
    }
    
    func finishExecution() async {
        let tag = [logTag, "execute"]
        
        // 清理超时
        timeoutTask?.cancel()
        timeoutTask = nil
        
        // 计算耗时
        let durationInfo = executeTime.map { duration in
            String(format: "duration=%.2fs", Date().timeIntervalSince(duration))
        } ?? ""
        
        // 计算成功/失败数
        var successCount = 0
        var failCount = 0
        if let st = internalState {
            let snap = await st.snapshot()
            for cr in snap.childResults {
                if case .success = cr {
                    successCount += 1
                } else if case .failure = cr {
                    failCount += 1
                }
            }
            // 若还有 nil（未设置），将其视为失败
            let nilCount = snap.childResults.filter { $0 == nil }.count
            failCount += nilCount
        } else {
            // 如果没有 internalState（极少数情况），将全部视为未完成/失败
            successCount = 0
            failCount = executables.count
        }
        let successInfo = String(format: "succ=%d/%d", successCount, executables.count)

        // 设置最终状态
        state = (allowPartialFailure || failCount == 0) ? .succeeded : .failed

        // 记录日志
        if state == .succeeded {
            XYLog.info(tag: tag, process: .succ, content: durationInfo, successInfo)
        } else {
            XYLog.info(tag: tag, process: .fail("部分命令失败"), content: durationInfo, successInfo)
        }

        // 释放内部 state，防止长期持有 actor（并允许下一次 run 重新初始化）
        internalState = nil
    }
}