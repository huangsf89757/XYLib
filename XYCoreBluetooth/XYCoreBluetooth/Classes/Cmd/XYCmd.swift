//
//  XYCmd.swift
//  Pods
//
//  Created by hsf on 2025/9/16.
//

import Foundation
import XYLog

// MARK: - XYCmd
open class XYCmd: XYCmdExecutable {
    public typealias ResultType = Any?
    
    // MARK: log
    public static let logTag = "Cmd"
    
    // MARK: var
    /// 唯一标识
    public let id: String
    
    /// 超时时间（秒）
    public let timeout: TimeInterval
    
    /// 用于管理超时和取消的 Task
    private var timeoutTask: DispatchWorkItem?
    
    /// 最大重试次数
    public let maxRetries: Int
    
    /// 当前已重试次数
    private var curRetries: Int = 0
    
    /// 命令运行状态
    public private(set) var state: XYCmdState = .idle {
        didSet {
            XYLog.info(tag: [Self.logTag, "state"], content: "id=\(id)", "\(oldValue) → \(state)")
        }
    }
    
    /// 子节点（预留，当前未使用）
    public var next: XYCmdExecutable?
    /// 父节点 (使用 weak 避免循环引用，预留)
    public weak var prev: XYCmdExecutable?
    
    /// 当前异步操作的 Continuation，用于在异步操作完成时恢复
    private var continuation: CheckedContinuation<Any?, Error>?
    
    /// 命令执行时间
    private var executeTime: Date?
    
    // MARK: init
    public init(id: String = UUID().uuidString,
                timeout: TimeInterval = 10,
                maxRetries: Int = 3) {
        self.id = id
        self.timeout = timeout
        self.maxRetries = maxRetries
    }
    
    // MARK: override
    /// 子类必须重写此方法以实现具体的命令逻辑。
    /// 这个方法应该只关注业务逻辑，不涉及超时和重试。
    /// - Throws: 如果命令执行过程中发生错误。
    /// - Returns: 命令执行成功后的结果。
    open func doCmd() async throws -> Any? {
        let tag = [Self.logTag, "execute"]
        let error = XYCmdError.notImplemented
        XYLog.info(tag: tag, process: .fail(error.info))
        throw error
    }
    
}

// MARK: - Public API
extension XYCmd {
    /// 执行命令。此方法包含了重试和超时逻辑。
    /// 应该由外部调用，而不是直接调用 `doCmd`。
    /// - Returns: 命令执行成功后的结果。
    /// - Throws: 如果命令执行失败，超时或被取消。
    @discardableResult
    public final func execute() async throws -> ResultType {
        let tag = [Self.logTag, "execute"]
        XYLog.info(tag: tag, process: .begin, content: "id=\(id)")
        
        if state == .cancelled {
            let err = XYCmdError.cancelled
            XYLog.info(tag: tag, process: .fail(err.info))
            throw err
        }
        
        if state == .executing {
            let err = XYCmdError.executing
            XYLog.info(tag: tag, process: .fail(err.info))
            throw err
        }
        state = .executing
        
        curRetries = 0 // 重置重试计数器
        
        while true {
            do {
                return try await withCheckedThrowingContinuation { continuation in
                    self.continuation = continuation
                    self.startTimeoutTask()
                    Task {
                        await self.executeOnce()
                    }
                }
            } catch let error {
                // 如果已取消，不重试
                if state == .cancelled {
                    let err = XYCmdError.cancelled
                    XYLog.info(tag: tag, process: .fail(err.info))
                    throw err
                }
                // 如果超出最大重试次数，不重试
                if curRetries >= maxRetries {
                    let err = XYCmdError.maxRetryExceeded
                    XYLog.info(tag: tag, process: .fail(err.info))
                    throw err
                }
                // 可根据错误类型决定是否重试（示例：超时和未知错误可重试）
                if let err = error as? XYCmdError {
                    switch err {
                    case .timeout, .other:
                        XYLog.info(tag: tag, process: .fail(err.info), content: "\(curRetries)/\(maxRetries)")
                        curRetries += 1
                        continue // 重试
                    default:
                        XYLog.info(tag: tag, process: .fail(err.info))
                        throw err
                    }
                } else {
                    let err = XYCmdError.unknown(error)
                    XYLog.info(tag: tag, process: .fail(err.info))
                    throw err
                }
            }
        }
    }
    
    /// 取消当前正在执行的命令。
    public func cancel() {
        let tag = [Self.logTag, "cancel"]
        state = .cancelled
        XYLog.info(tag: tag, content: "id=\(id)")
        timeoutTask?.cancel()
        timeoutTask = nil
        // 只有当 continuation 存在且未被 resume 时才触发取消
        if let continuation = self.continuation {
            self.continuation = nil
            continuation.resume(throwing: XYCmdError.cancelled)
        }
    }
}

// MARK: - Private Helpers
private extension XYCmd {
    /// 执行单次命令（不含重试）
    private func executeOnce() async {
        do {
            executeTime = Date()
            let result = try await doCmd()
            finishExecution(with: .success(result))
        } catch let error {
            finishExecution(with: .failure(error))
        }
    }
    
    /// 设置超时任务。
    func startTimeoutTask() {
        let tag = [Self.logTag, "timeout"]
        timeoutTask?.cancel()
        let task = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            XYLog.info(tag: tag, content: "did", "id=\(id)")
            self.finishExecution(with: .failure(XYCmdError.timeout))
        }
        timeoutTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout, execute: task)
        XYLog.info(tag: tag, content: "start", "id=\(id)", "\(timeout)")
    }
        
    /// 完成命令执行，无论是成功还是失败。
    func finishExecution(with result: Result<Any?, Error>) {
        let tag = [Self.logTag, "execute"]
        // 取消超时任务
        timeoutTask?.cancel()
        timeoutTask = nil
        // 仅当 continuation 存在时才 resume（避免重复调用崩溃）
        if let continuation = self.continuation {
            self.continuation = nil
            var durationInfo = ""
            if let duration = executeTime.map({ Date().timeIntervalSince($0) }) {
                durationInfo = String(format: "duration=%.2fs", duration)
            }
            
            switch result {
            case .success(let value):
                state = .succeeded
                XYLog.info(tag: tag, process: .succ, content: durationInfo)
                continuation.resume(returning: value)
            case .failure(let error):
                var err: XYCmdError
                if let e = error as? XYCmdError {
                    err = e
                } else {
                    let e = XYCmdError.unknown(error)
                    err = e
                }
                state = .failed
                XYLog.info(tag: tag, process: .fail(err.info), content: durationInfo)
                continuation.resume(throwing: error)
            }
        }
    }
}
