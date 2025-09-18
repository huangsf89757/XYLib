//
//  XYCmdGroup.swift
//  Pods
//
//  Created by hsf on 2025/9/17.
//

import Foundation
import XYLog

// MARK: - XYCmdGroup
open class XYCmdGroup: XYCmdExecutable {
    public typealias ResultType = [Any?]
        
    // MARK: log
    public static let logTag = "CmdGroup"
    
    // MARK: var
    /// 唯一标识
    public let id: String
    
    /// 子命令列表
    public let cmds: [XYCmdExecutable]
    
    /// 执行模式
    public let mode: ExecutionMode
    
    /// 整体超时时间（秒），0 表示无超时
    public let timeout: TimeInterval
    
    /// 是否允许部分失败（true = 部分失败仍继续，false = 任一失败立即停止）
    public let allowPartialFailure: Bool
    
    /// 当前状态
    public private(set) var state: XYCmdState = .idle {
        didSet {
            XYLog.info(tag: [Self.logTag, "state"], content: "id=\(id)", "\(oldValue) → \(state)")
        }
    }
    
    /// 子节点（预留，当前未使用）
    public var next: XYCmdExecutable?
    /// 父节点 (使用 weak 避免循环引用，预留)
    public weak var prev: XYCmdExecutable?
    
    /// 收集的错误
    private var collectedErrors: [XYCmdError] = []
    
    /// 已完成的命令数
    private var completedCount = 0
    
    /// 收集到的结果（失败为 nil）
    private var executionResults: [Any?] = []
    
    /// 用于管理超时的 Task
    private var timeoutTask: DispatchWorkItem?
    
    /// 命令开始时间
    private var executeTime: Date?
    
    // MARK: init
    public init(
        id: String = UUID().uuidString,
        cmds: [XYCmdExecutable],
        mode: ExecutionMode = .concurrent,
        timeout: TimeInterval = 0,
        allowPartialFailure: Bool = false
    ) {
        self.id = id
        self.cmds = cmds
        self.mode = mode
        self.timeout = timeout
        self.allowPartialFailure = allowPartialFailure
    }
    
    public convenience init(
        id: String = UUID().uuidString,
        cmds: [XYCmd],
        mode: ExecutionMode = .concurrent,
        timeout: TimeInterval = 0,
        allowPartialFailure: Bool = false
    ) {
        self.init(id: id, cmds: cmds, mode: mode, timeout: timeout, allowPartialFailure: allowPartialFailure)
    }
    
    public convenience init(
        id: String = UUID().uuidString,
        groups: [XYCmdGroup],
        mode: ExecutionMode = .concurrent,
        timeout: TimeInterval = 0,
        allowPartialFailure: Bool = false
    ) {
        self.init(id: id, cmds: groups, mode: mode, timeout: timeout, allowPartialFailure: allowPartialFailure)
    }
    
    public convenience init(
        id: String = UUID().uuidString,
        cmdsAndGroups: [XYCmdExecutable],
        mode: ExecutionMode = .concurrent,
        timeout: TimeInterval = 0,
        allowPartialFailure: Bool = false
    ) {
        self.init(id: id, cmds: cmdsAndGroups, mode: mode, timeout: timeout, allowPartialFailure: allowPartialFailure)
    }
    
    /// 暴露收集到的错误
    public var errors: [XYCmdError] { collectedErrors }
}

// MARK: - ExecutionMode
extension XYCmdGroup {
    public enum ExecutionMode {
        case concurrent  // 并行执行
        case sequential  // 串行执行
    }
}

// MARK: - Public API
extension XYCmdGroup {
    
    @discardableResult
    public func execute() async throws -> ResultType {
        let tag = [Self.logTag, "execute"]
        XYLog.info(tag: tag, process: .begin, content: "id=\(id), mode=\(mode), count=\(cmds.count)")
        
        guard state != .cancelled else {
            let error = XYCmdError.cancelled
            XYLog.info(tag: tag, process: .fail(error.info))
            throw error
        }
        
        guard state != .executing else {
            let error = XYCmdError.executing
            XYLog.info(tag: tag, process: .fail(error.info))
            throw error
        }
        
        state = .executing
        executeTime = Date()
        executionResults = Array(repeating: nil, count: cmds.count)
        completedCount = 0
        collectedErrors.removeAll()
        startTimeoutTask()
        
        do {
            if mode == .concurrent {
                try await executeConcurrently()
            } else {
                try await executeSequentially()
            }
            
            // ✅ 保证在所有路径中调用 finishExecution
            finishExecution()
            
            // 如果不允许部分失败且有错误，抛出第一个错误
            if !allowPartialFailure, let firstError = collectedErrors.first {
                throw firstError
            }
            
            return executionResults
        } catch {
            finishExecution() // ✅ 确保清理资源
            if state == .cancelled {
                throw XYCmdError.cancelled
            } else {
                throw error
            }
        }
    }
    
    public func cancel() {
        let tag = [Self.logTag, "cancel"]
        state = .cancelled
        XYLog.info(tag: tag, content: "id=\(id)")
        
        timeoutTask?.cancel()
        timeoutTask = nil
        
        // 取消所有子命令
        for cmd in cmds {
            cmd.cancel()
        }
    }
}

// MARK: - Private Execution
private extension XYCmdGroup {
    
    func executeConcurrently() async throws {
        let tag = [Self.logTag, "concurrent"]
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
        let tag = [Self.logTag, "sequential"]
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
                tag: [Self.logTag, "child"],
                process: .succ,
                content: "id=\(id)", "childId=\(cmds[index].id)", "result=\(String(describing: value))"
            )
            
        case .failure(let error):
            executionResults[index] = nil
            
            let cmdError: XYCmdError = (error as? XYCmdError) ?? .unknown(error)
            collectedErrors.append(cmdError)
            
            // 记录子组失败（即使没有错误详情）
            if let subGroup = cmds[index] as? XYCmdGroup, subGroup.state == .failed {
                collectedErrors.append(.other(nil)) // 可替换为更具体的错误
            }
            
            XYLog.info(
                tag: [Self.logTag, "child"],
                process: .fail(cmdError.info),
                content: "id=\(id)", "childId=\(cmds[index].id)"
            )
        }
    }
    
    func finishExecution() {
        let tag = [Self.logTag, "execute"]
        
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
    
    func startTimeoutTask() {
        guard timeout > 0 else { return }
        let tag = [Self.logTag, "timeout"]
        let task = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            XYLog.info(tag: tag, content: "did", "id=\(self.id)")
            self.cancel()
        }
        timeoutTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout, execute: task)
        XYLog.info(tag: tag, content: "start", "id=\(id)", "\(timeout)s")
    }
}
