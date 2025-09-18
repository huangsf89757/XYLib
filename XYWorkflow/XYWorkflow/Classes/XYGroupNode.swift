//
//  XYGroupNode.swift
//  Pods
//
//  Created by hsf on 2025/9/17.
//

import Foundation
import XYLog

// MARK: - XYGroupNode
open class XYGroupNode: XYNode<[Any?]> {
    
    // MARK: var
    /// 子命令列表
    public let cmds: [XYExecutable]
    /// 执行模式
    public let mode: ExecutionMode
    /// 是否允许部分失败（true = 部分失败仍继续，false = 任一失败立即停止）
    public let allowPartialFailure: Bool
    /// 收集的错误
    fileprivate var collectedErrors: [XYError] = []
    /// 已完成的命令数
    private var completedCount = 0
    /// 收集到的结果（失败为 nil）
    private var executionResults: [Any?] = []
    
    
    // MARK: init
    public init(
        id: String = UUID().uuidString,
        timeout: TimeInterval = 0,
        cmds: [XYExecutable],
        mode: ExecutionMode = .concurrent,
        allowPartialFailure: Bool = false
    ) {
        self.cmds = cmds
        self.mode = mode
        self.allowPartialFailure = allowPartialFailure
        super.init(id: id, timeout: timeout)
        self.logTag = "Flow.N.B"
    }
    
    public convenience init(id: String = UUID().uuidString,
                            timeout: TimeInterval = 30,
                            cmds: [XYBaseNode<Any>],
                            mode: ExecutionMode = .concurrent,
                            
                            allowPartialFailure: Bool = false) {
        self.init(id: id, timeout: timeout, cmds: cmds, mode: mode, allowPartialFailure: allowPartialFailure)
    }
    
    public convenience init(id: String = UUID().uuidString,
                            timeout: TimeInterval = 0,
                            groups: [XYGroupNode],
                            mode: ExecutionMode = .concurrent,
                            allowPartialFailure: Bool = false) {
        self.init(id: id, timeout: timeout, cmds: groups, mode: mode, allowPartialFailure: allowPartialFailure)
    }
    
    public convenience init(id: String = UUID().uuidString,
                            timeout: TimeInterval = 0,
                            cmdsAndGroups: [XYExecutable],
                            mode: ExecutionMode = .concurrent,
                            allowPartialFailure: Bool = false) {
        self.init(id: id, timeout: timeout, cmds: cmdsAndGroups, mode: mode, allowPartialFailure: allowPartialFailure)
    }
    
    
    // MARK: override
    @discardableResult
    public override func run() async throws -> ResultType {
        let tag = [logTag, "execute"]
        XYLog.info(tag: tag, process: .begin, content: "id=\(id), mode=\(mode), count=\(cmds.count)")
        
        executionResults = Array(repeating: nil, count: cmds.count)
        completedCount = 0
        collectedErrors.removeAll()
        startTimeoutTask()
        defer { finishExecution() }
        
        do {
            if mode == .concurrent {
                try await executeConcurrently()
            } else {
                try await executeSequentially()
            }
            // 如果不允许部分失败且有错误，抛出第一个错误
            if !allowPartialFailure, let firstError = collectedErrors.first {
                throw firstError
            }
            return executionResults
        } catch {
            if state == .cancelled {
                throw XYError.cancelled
            } else {
                throw error
            }
        }
    }
    
    public override func cancel() {
        super.cancel()
        for cmd in cmds {
            cmd.cancel()
        }
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
            for (index, cmd) in cmds.enumerated() {
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
                handleCommandResult(at: index, result: result)
                
                // 如果不允许部分失败且已有失败，取消剩余
                if !allowPartialFailure, !collectedErrors.isEmpty {
                    group.cancelAll()
                    break
                }
            }
        }
    }
    
    func executeSequentially() async throws {
        let tag = [logTag, "sequential"]
        XYLog.info(tag: tag, content: "start", "id=\(id)")
        
        for (index, cmd) in cmds.enumerated() {
            do {
                let result = try await cmd.execute()
                handleCommandResult(at: index, result: .success(result))
            } catch let error {
                handleCommandResult(at: index, result: .failure(error))
                if !allowPartialFailure {
                    throw error // 立即中断
                }
            }
        }
    }
    
    func handleCommandResult(at index: Int, result: Result<Any?, Error>) {
        guard index < cmds.count else { return }
        completedCount += 1
        let childCmd = cmds[index]
        
        switch result {
        case .success(let value):
            executionResults[index] = value
            XYLog.debug(
                tag: [logTag, "child"],
                process: .succ,
                content: "id=\(id)", "childId=\(cmds[index].id)", "result=\(String(describing: value))"
            )
            
        case .failure(let error):
            executionResults[index] = nil
            
            let cmdError: XYError = (error as? XYError) ?? .unknown(error)
            collectedErrors.append(cmdError)
            
            // 收集子组的具体错误信息
            if let subGroup = cmds[index] as? XYGroupNode, 
               subGroup.state == .failed, 
               !subGroup.collectedErrors.isEmpty {
            collectedErrors.append(contentsOf: subGroup.collectedErrors)
            } else if let subGroup = cmds[index] as? XYGroupNode,
                      subGroup.state == .failed {
            // 如果子组没有具体错误，添加上下文信息
            let contextError = NSError(domain: "XYWorkflow", code: 0, userInfo: [NSLocalizedDescriptionKey: "SubGroup \(subGroup.id) failed without specific error"])
            collectedErrors.append(.other(contextError))
            }
            
            XYLog.info(
                tag: [logTag, "child"],
                process: .fail(cmdError.info),
                content: "id=\(id)", "childId=\(cmds[index].id)"
            )
        }
    }
    
    func finishExecution() {
        let tag = [logTag, "execute"]
        
        // 清理超时
        timeoutTask?.cancel()
        timeoutTask = nil
        
        // 计算耗时
        let durationInfo = executeTime.map { duration in
            String(format: "duration=%.2fs", Date().timeIntervalSince(duration))
        } ?? ""
        
        let successCount = executionResults.compactMap { $0 }.count
        let failCount = executionResults.count - successCount
        let successInfo = String(format: "succ=%d/%d", successCount, executionResults.count)
        
        // 设置最终状态
        state = (allowPartialFailure || failCount == 0) ? .succeeded : .failed
        
        // 记录日志
        if state == .succeeded {
            XYLog.info(tag: tag, process: .succ, content: durationInfo, successInfo)
        } else {
            XYLog.info(tag: tag, process: .fail("部分命令失败"), content: durationInfo, successInfo)
        }
    }
}
