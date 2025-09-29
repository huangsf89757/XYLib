//
//  XYCmd.swift
//  Pods
//
//  Created by hsf on 2025/9/18.
//

import Foundation
import XYExtension
import XYLog

// MARK: - XYCmd
open class XYCmd<ResultType>: XYExecutable {
    // MARK: log
    public internal(set) var logTag = "WorkFlow.Cmd"
    
    // MARK: XYExecutable
    /// 唯一标识
    public let id: String
    
    // === 命令执行 ===
    /// 命令开始时间
    public private(set) var executeTime: Date?
    /// 命令完成时间
    public private(set) var finishTime: Date?
    /// 命令执行状态
    public private(set) var state: XYState = .idle {
        didSet {
            XYLog.info(tag: [logTag, "state"], content: "id=\(id)", "\(oldValue) → \(state)")
        }
    }
    
    // === 超时 ===
    /// 超时时间（秒），<=0 表示无超时
    public let timeout: TimeInterval
    
    // === 重试 ===
    /// 最大重试次数。`nil` 或 `<= 0` 表示不重试。
    public let maxRetries: Int?
    /// 当前已重试次数
    public private(set) var curRetries: Int = 0
    /// 重试之间的延迟（秒）
    public let retryDelay: TimeInterval?
    
    // === 执行内容 ===
    public let executionBlock: ((@escaping (Result<ResultType, Error>) -> Void) -> Void)?
    
    // MARK: init
    public init(id: String = UUID().uuidString,
                timeout: TimeInterval = 10,
                maxRetries: Int? = nil,
                retryDelay: TimeInterval? = nil,
                executionBlock: ((@escaping (Result<ResultType, Error>) -> Void) -> Void)? = nil) {
        self.id = id
        self.timeout = timeout
        self.maxRetries = maxRetries
        self.retryDelay = retryDelay
        self.executionBlock = executionBlock
    }
    
    // MARK: - Public Methods
    
    /// 执行命令（主入口）
    @discardableResult
    public final func execute() async throws -> ResultType {
        let tag = [logTag, "execute"]
        XYLog.info(id: id, tag: tag, process: .begin)
        
        // 状态检查
        if state == .cancelled {
            let finalError = XYError.cancelled
            finishExecution(tag: tag, state: .cancelled, result: nil, error: finalError)
            throw finalError
        }
        if state == .executing {
            let finalError = XYError.executing
            finishExecution(tag: tag, state: .failed, result: nil, error: finalError)
            throw finalError
        }
        
        // 初始化执行
        state = .executing
        executeTime = Date()
        curRetries = 0
        
        // 重试循环
        while true {
            // 每次重试前检查是否已被取消
            if state == .cancelled {
                let finalError = XYError.cancelled
                finishExecution(tag: tag, state: .cancelled, result: nil, error: finalError)
                throw finalError
            }

            do {
                let result: ResultType
                // 包装执行逻辑（含超时）
                if let block = executionBlock {
                    result = try await withTimeout(timeout) {
                        return try await withCheckedThrowingContinuation { continuation in
                            var hasResumed = false
                            block { result in
                                guard !hasResumed else {
                                    return // 防止多次回调
                                }
                                hasResumed = true
                                switch result {
                                case .success(let value):
                                    continuation.resume(returning: value)
                                case .failure(let error):
                                    continuation.resume(throwing: error)
                                }
                            }
                        }
                    }
                } else {
                    result = try await withTimeout(timeout) {
                        return try await self.run()
                    }
                }
                // 成功：结束执行
                finishExecution(tag: tag, state: .succeeded, result: result, error: nil)
                return result
                
            } catch let error {
                // 检查是否已被取消（可能由外部 cancel() 触发）
                if state == .cancelled {
                    let finalError = XYError.cancelled
                    finishExecution(tag: tag, state: .cancelled, result: nil, error: finalError)
                    throw finalError
                }
                
                // 判断是否支持重试
                guard let maxRetries = self.maxRetries, maxRetries > 0 else {
                    let finalError = normalizeError(error)
                    finishExecution(tag: tag, state: .failed, result: nil, error: finalError)
                    throw finalError
                }
                
                // 判断当前错误是否可重试
                guard checkErrorRetryEnable(error: error) else {
                    let finalError = normalizeError(error)
                    finishExecution(tag: tag, state: .failed, result: nil, error: finalError)
                    throw finalError
                }
                
                // 超出最大重试次数？
                if curRetries >= maxRetries {
                    let finalError = XYError.maxRetryExceeded
                    finishExecution(tag: tag, state: .failed, result: nil, error: finalError)
                    throw finalError
                }
                
                // 重试延迟
                if let retryDelay = retryDelay, retryDelay > 0 {
                    try await Task.sleep(seconds: retryDelay)
                }
                
                // 重试
                curRetries += 1
                XYLog.info(
                    id: id,
                    tag: tag,
                    process: .fail((error as? XYError)?.info ?? "Retryable error"),
                    content: "retry=\(curRetries)/\(maxRetries)"
                )
            }
        }
    }
    
    /// 子类重写此方法提供实际执行逻辑
    open func run() async throws -> ResultType {
        // 执行前检查是否已被取消
        if state == .cancelled {
            throw XYError.cancelled
        }
        let tag = [logTag, "run"]
        let error = XYError.notImplemented
        XYLog.info(id: id, tag: tag, process: .fail(error.info))
        throw error
    }
    
    /// 取消执行
    public func cancel() {
        let tag = [logTag, "cancel"]
        guard state != .cancelled else { return }
        finishExecution(tag: tag, state: .cancelled, result: nil, error: XYError.cancelled)
    }
    
    
    // MARK: - Private Helpers
    
    /// 判断错误是否可重试
    private func checkErrorRetryEnable(error: Error) -> Bool {
        if let err = error as? XYError {
            switch err {
            case .timeout, .other: // 超时和其他错误可重试
                return true
            default:
                return false
            }
        }
        return false // 非 XYError 默认不重试
    }
    
    /// 标准化错误为 XYError（安全处理 nil）
    private func normalizeError(_ error: Error?) -> XYError {
        if let err = error as? XYError {
            return err
        }
        return XYError.unknown(error)
    }
    
    /// 完成执行（更新状态、时间、日志）
    private func finishExecution(tag: [String], state: XYState, result: ResultType?, error: Error?) {
        let now = Date()
        finishTime = now
        self.state = state
        
        let durationInfo: String
        if let executeTime = executeTime {
            let duration = now.timeIntervalSince(executeTime)
            durationInfo = String(format: "duration=%.2fs", duration)
        } else {
            durationInfo = "duration=N/A"
        }
        
        switch state {
        case .idle, .executing:
            // 正常流程不应走到这里
            break
        case .succeeded:
            XYLog.info(id: id, tag: tag, process: .succ, content: durationInfo)
        case .failed, .cancelled:
            let err = normalizeError(error)
            XYLog.info(id: id, tag: tag, process: .fail(err.info), content: durationInfo)
        }
    }
    
    /// 带超时的异步操作包装
    private func withTimeout<T>(_ seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        guard seconds > 0 else {
            return try await operation()
        }
        
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                return try await operation()
            }
            group.addTask {
                try await Task.sleep(seconds: seconds)
                throw XYError.timeout
            }

            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}
