//
//  XYCmd.swift
//  Pods
//
//  Created by hsf on 2025/9/18.
//

import Foundation
import XYUtil
import XYExtension
import XYLog

// MARK: - XYCmd
open class XYCmd<ResultType>: XYExecutable {
    // MARK: log
    public private(set) var logTag = "WorkFlow.Cmd"
    
    // MARK: timing
    private var startTime: UInt64 = 0
    private var timebaseInfo = mach_timebase_info()
    
    // MARK: identifier
    public let id: XYIdentifier
    
    // MARK: execution
    public private(set) var executeTask: Task<ResultType, any Error>?
    public private(set) var executeTime: Date?
    public private(set) var finishTime: Date?
    public private(set) var state: XYState = .idle {
        didSet {
            XYLog.info(id: id, tag: [logTag, "state"], content: "\(oldValue) → \(state)")
        }
    }
    public let executionBlock: ((@escaping (Result<ResultType, Error>) -> Void) -> Void)?
    
    // MARK: timeout
    public let timeout: TimeInterval
    
    // MARK: retry
    public let maxRetries: Int?
    public private(set) var curRetries: Int = 0
    public let retryDelay: TimeInterval?
    
    // MARK: hock
    public var onWillExecute: (() -> Void)?
    public var onDidExecute: ((Result<ResultType, Error>) -> Void)?
    public var onRetry: ((Error, Int) -> Void)?
    
    // MARK: private properties
    /// 在group中是否允许失败
    public var allowsFailureInGroup: Bool = true
    
    // MARK: init
    public init(id: XYIdentifier = UUID().uuidString,
                timeout: TimeInterval = 10,
                maxRetries: Int? = nil,
                retryDelay: TimeInterval? = nil,
                executionBlock: ((@escaping (Result<ResultType, Error>) -> Void) -> Void)? = nil) {
        self.id = id
        self.timeout = timeout
        self.maxRetries = maxRetries
        self.retryDelay = retryDelay
        self.executionBlock = executionBlock
        
        if timebaseInfo.denom == 0 {
            mach_timebase_info(&timebaseInfo)
        }
    }
    
    // MARK: execute
    @discardableResult
    public final func execute() async throws -> ResultType {
        let tag = [logTag, "execute"]
        XYLog.info(id: id, tag: tag, process: .begin)
        
        onWillExecute?()
        
        // 状态检查
        if state == .cancelled {
            let finalError = XYError.cancelled
            finishExecution(tag: tag, state: .cancelled, result: nil, error: finalError)
            onDidExecute?(.failure(finalError))
            throw finalError
        }
        if state == .executing {
            let finalError = XYError.executing
            finishExecution(tag: tag, state: .failed, result: nil, error: finalError)
            onDidExecute?(.failure(finalError))
            throw finalError
        }
        
        // 创建一个可取消的任务
        let executeTask = Task {
            return try await executeImplementation()
        }
        self.executeTask = executeTask
        
        do {
            let result = try await executeTask.value
            return result
        } catch {
            // 如果任务被取消，抛出取消错误
            if executeTask.isCancelled {
                let finalError = XYError.cancelled
                finishExecution(tag: tag, state: .cancelled, result: nil, error: finalError)
                onDidExecute?(.failure(finalError))
                throw finalError
            }
            throw error
        }
    }
    
    // MARK: run
    /// 子类重写此方法提供实际执行逻辑
    open func run() async throws -> ResultType {
        let tag = [logTag, "run"]
        let error = XYError.notImplemented
        XYLog.info(id: id, tag: tag, process: .fail(error.info))
        throw error
    }
    
    // MARK: cancel
    public final func cancel() {
        let tag = [logTag, "cancel"]
        guard state != .cancelled else { return }
        executeTask?.cancel()
        finishExecution(tag: tag, state: .cancelled, result: nil, error: XYError.cancelled)
    }
}

// MARK: - Execution Implementation
extension XYCmd {
    private func executeImplementation() async throws -> ResultType {
        let tag = [logTag, "execute"]
        
        // 初始化执行
        state = .executing
        executeTime = Date()
        curRetries = 0
        startTiming()
        
        // 重试循环
        while true {
            do {
                // 检查取消状态
                if state == .cancelled || Task.isCancelled {
                    let finalError = XYError.cancelled
                    finishExecution(tag: tag, state: .cancelled, result: nil, error: finalError)
                    onDidExecute?(.failure(finalError))
                    throw finalError
                }
                
                let result: ResultType
                // 包装执行逻辑（含超时）
                if let block = executionBlock {
                    result = try await withTimeout(timeout) { [weak self] in
                        guard let self = self else { throw XYError.cancelled }
                        return try await withCheckedThrowingContinuation { [weak self] continuation in
                            guard let strongSelf = self else {
                                continuation.resume(throwing: XYError.cancelled)
                                return
                            }
                            
                            var hasResumed = false
                            block { result in
                                guard !hasResumed, strongSelf.state != .cancelled, !Task.isCancelled else {
                                    return // 防止多次回调和检查取消状态
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
                    result = try await withTimeout(timeout) { [weak self] in
                        guard let self = self else { throw XYError.cancelled }
                        return try await self.run()
                    }
                }
                
                // 检查取消状态
                if state == .cancelled || Task.isCancelled {
                    let finalError = XYError.cancelled
                    finishExecution(tag: tag, state: .cancelled, result: nil, error: finalError)
                    onDidExecute?(.failure(finalError))
                    throw finalError
                }
                
                finishExecution(tag: tag, state: .succeeded, result: result, error: nil)
                onDidExecute?(.success(result))
                return result
                
            } catch let error {
                // 检查是否已被取消
                if state == .cancelled || Task.isCancelled {
                    let finalError = XYError.cancelled
                    finishExecution(tag: tag, state: .cancelled, result: nil, error: finalError)
                    onDidExecute?(.failure(finalError))
                    throw finalError
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
                    if state == .cancelled || Task.isCancelled {
                        let finalError = XYError.cancelled
                        finishExecution(tag: tag, state: .cancelled, result: nil, error: finalError)
                        onDidExecute?(.failure(finalError))
                        throw finalError
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
}

// MARK: - Func
extension XYCmd {
    private func startTiming() {
        startTime = mach_absolute_time()
    }
    
    private func getDuration() -> TimeInterval {
        let endTime = mach_absolute_time()
        let elapsed = endTime - startTime
        let nanoseconds = elapsed * UInt64(timebaseInfo.numer) / UInt64(timebaseInfo.denom)
        return TimeInterval(nanoseconds) / 1_000_000_000
    }
    
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
        if executeTime != nil {
            let duration = getDuration()
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
    
    /// 带超时的异步操作包装
    private func withTimeout<T>(_ seconds: TimeInterval,
                                operation: @escaping () async throws -> T) async throws -> T {
        guard seconds > 0 else {
            return try await operation()
        }
        
        return try await withThrowingTaskGroup(of: T.self) { group in
            // 主操作任务
            group.addTask {
                return try await operation()
            }
            // 超时任务
            group.addTask {
                try await Task.sleep(seconds: seconds)
                throw XYError.timeout
            }
            // defer
            defer {
                group.cancelAll()
            }
            // result
            if let result = try await group.next() {
                return result
            }
            let fallbackError = NSError(
                domain: "XYCmd.TimeoutError",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Timeout task group returned no result"]
            )
            throw XYError.unknown(fallbackError)
        }
    }
}
