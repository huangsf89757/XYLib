//
//  XYCmd.swift
//  XYWorkflow
//
//  Created by hsf on 2025/9/18.
//

import Foundation
import XYUtil
import XYExtension
import XYLog

// MARK: - XYCmd
open class XYCmd<ResultType> {
    // MARK: log
    public internal(set) var logTag = "WorkFlow.Cmd"
        
    // MARK: identifier
    public let id: XYIdentifier
    
    // MARK: execution
    public internal(set) var executeTask: Task<ResultType, any Error>?
    public internal(set) var executeTime: Date?
    public internal(set) var finishTime: Date?
    public internal(set) var state: XYState = .idle {
        didSet {
            XYLog.info(id: id, tag: [logTag, "state"], content: "\(oldValue) → \(state)")
        }
    }
    
    // MARK: timeout
    public let timeout: TimeInterval
    
    // MARK: retry
    public let maxRetries: Int?
    public internal(set) var curRetries: Int = 0
    public let retryDelay: TimeInterval?
    
    // MARK: hock
    public var onWillExecute: (() -> Void)?
    public var onDidExecute: ((Result<ResultType, Error>) -> Void)?
    public var onRetry: ((Error, Int) -> Void)?
    
    // MARK: init
    public init(id: XYIdentifier = UUID().uuidString,
                timeout: TimeInterval = 10,
                maxRetries: Int? = nil,
                retryDelay: TimeInterval? = nil) {
        self.id = id
        self.timeout = timeout
        self.maxRetries = maxRetries
        self.retryDelay = retryDelay
    }
    
    // MARK: execute
    @discardableResult
    public final func execute() async throws -> ResultType {
        let tag = [logTag, "execute"]
        XYLog.info(id: id, tag: tag, process: .begin)
        
        onWillExecute?()
        
        // 状态检查
        if state == .cancelled {
            return try await handleCancellationIfNeeded(tag: tag)
        }
        if state == .executing {
            let finalError = XYError.executing
            finishExecution(tag: tag, state: .failed, result: nil, error: finalError)
            onDidExecute?(.failure(finalError))
            throw finalError
        }
        
        // 创建一个可取消的任务
        let executeTask = Task {
            return try await executeImp()
        }
        self.executeTask = executeTask
        
        do {
            let result = try await executeTask.value
            return result
        } catch {
            // 如果任务被取消，抛出取消错误
            if executeTask.isCancelled || isCancelled() {
                return try await handleCancellationIfNeeded(tag: tag)
            }
            throw error
        }
    }
    
    /// 处理取消逻辑
    private func handleCancellationIfNeeded(tag: [String]) async throws -> ResultType {
        let finalError = XYError.cancelled
        finishExecution(tag: tag, state: .cancelled, result: nil, error: finalError)
        onDidExecute?(.failure(finalError))
        throw finalError
    }
    
    private func executeImp() async throws -> ResultType {
        let tag = [logTag, "execute"]
        
        // 初始化执行
        state = .executing
        executeTime = Date()
        curRetries = 0
        
        // 重试循环
        while true {
            // 执行前检查取消状态
            if isCancelled() {
                return try await handleCancellationIfNeeded(tag: tag)
            }
            
            do {
                let result = try await executeWithTimeout()
                
                // 执行后检查取消状态
                if isCancelled() {
                    return try await handleCancellationIfNeeded(tag: tag)
                }
                
                finishExecution(tag: tag, state: .succeeded, result: result, error: nil)
                onDidExecute?(.success(result))
                return result
                
            } catch let error {
                // 检查是否已被取消
                if isCancelled() || Task.isCancelled {
                    return try await handleCancellationIfNeeded(tag: tag)
                }
                
                // 判断是否支持重试
                guard let maxRetries = self.maxRetries, maxRetries > 0 else {
                    let finalError = normalizeError(error)
                    finishExecution(tag: tag, state: .failed, result: nil, error: finalError)
                    onDidExecute?(.failure(finalError))
                    throw finalError
                }
                
                // 判断当前错误是否可重试
                guard checkErrorRetryEnable(error: error) else {
                    let finalError = normalizeError(error)
                    finishExecution(tag: tag, state: .failed, result: nil, error: finalError)
                    onDidExecute?(.failure(finalError))
                    throw finalError
                }
                
                // 超出最大重试次数？
                if curRetries >= maxRetries {
                    let finalError = XYError.maxRetryExceeded
                    finishExecution(tag: tag, state: .failed, result: nil, error: finalError)
                    onDidExecute?(.failure(finalError))
                    throw finalError
                }
                
                // 重试延迟 - 检查取消状态
                if let retryDelay = retryDelay, retryDelay > 0 {
                    try await Task.sleep(seconds: retryDelay)
                    if isCancelled() || Task.isCancelled {
                        return try await handleCancellationIfNeeded(tag: tag)
                    }
                }
                
                // 重试
                curRetries += 1
                onRetry?(error, curRetries)
                XYLog.info(
                    id: id,
                    tag: tag,
                    process: .fail((error as? XYError)?.info ?? "Retryable error"),
                    content: "retry=\(curRetries)/\(maxRetries)"
                )
            }
        }
    }
    
    private func executeWithTimeout() async throws -> ResultType {
        return try await withTimeout(timeout) { [weak self] in
            guard let self = self else { throw XYError.cancelled }
            return try await self.run()
        }
    }
    
    // MARK: run
    open func run() async throws -> ResultType {
        let tag = [logTag, "run"]
        let error = XYError.notImplemented
        XYLog.info(id: id, tag: tag, process: .fail(error.info))
        throw error
    }
    
    // MARK: cancel
    open func cancel() {
        let tag = [logTag, "cancel"]
        guard state != .cancelled else { return }
        executeTask?.cancel()
        finishExecution(tag: tag, state: .cancelled, result: nil, error: XYError.cancelled)
    }
}

// MARK: - State
extension XYCmd {
    /// 是否正在执行
    public var isExecuting: Bool {
        return state == .executing
    }
    
    /// 是否已完成
    public var isCompleted: Bool {
        return state == .succeeded || state == .failed || state == .cancelled
    }
}

// MARK: Execute
extension XYCmd {
    /// 当前执行是否已取消
    public func isCancelled() -> Bool {
        return state == .cancelled || Task.isCancelled
    }
        
    /// 完成执行（更新状态、时间、日志）
    public func finishExecution(tag: [String], state: XYState, result: ResultType?, error: Error?) {
        // 防止重复设置状态
        guard self.state != .cancelled || state == .cancelled else { return }
        
        let finishTime = Date()
        self.finishTime = finishTime
        self.state = state
        
        let durationInfo: String
        if let executeTime = executeTime {
            let duration = executeTime.distance(to: finishTime)
            durationInfo = String(format: "duration=%.3fs", duration)
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
}

// MARK: Error
extension XYCmd {
    /// 标准化错误为 XYError（安全处理 nil）
    public func normalizeError(_ error: Error?) -> XYError {
        if let err = error as? XYError {
            return err
        }
        return XYError.unknown(error)
    }
    
    /// 判断错误是否可重试
    public func checkErrorRetryEnable(error: Error) -> Bool {
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
}

// MARK: Timeout
extension XYCmd {
    /// 带超时的异步操作包装
    public func withTimeout<T>(_ seconds: TimeInterval,
                               operation: @escaping () async throws -> T) async throws -> T {
        guard seconds > 0 else {
            return try await operation()
        }
        
        return try await withThrowingTaskGroup(of: T.self) { [weak self] group in
            guard let self = self else {
                throw XYError.cancelled
            }
            
            // 主操作任务
            let operationTask = group.addTaskUnlessCancelled {
                return try await operation()
            }
            
            // 如果添加任务失败（因为group已被取消），直接抛出取消错误
            guard operationTask != nil else {
                throw XYError.cancelled
            }
            
            // 超时任务
            let timeoutTask = group.addTaskUnlessCancelled {
                try await Task.sleep(seconds: seconds)
                throw XYError.timeout
            }
            
            // 如果添加超时任务失败，确保取消主任务
            guard timeoutTask != nil else {
                throw XYError.cancelled
            }
            
            // 等待第一个完成的任务
            do {
                if let result = try await group.next() {
                    // 取消剩余任务
                    group.cancelAll()
                    return result
                } else {
                    // 这种情况理论上不会发生，但为了安全起见处理一下
                    group.cancelAll()
                    let fallbackError = NSError(
                        domain: "XYWorkflow",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Timeout task group returned no result"]
                    )
                    throw XYError.unknown(fallbackError)
                }
            } catch {
                // 取消所有任务并重新抛出错误
                group.cancelAll()
                
                // 检查是否是由于取消导致的错误
                if self.isCancelled() || Task.isCancelled {
                    throw XYError.cancelled
                }
                
                throw error
            }
        }
    }
}
