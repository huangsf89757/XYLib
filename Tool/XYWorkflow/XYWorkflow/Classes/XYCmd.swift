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
open class XYCmd<ResultType>: XYExecutable {
    // MARK: log
    public internal(set) var logTag = "WorkFlow.Cmd"
        
    // MARK: identifier
    public let id: XYIdentifier
    
    // MARK: execution
    public var executeTask: Task<ResultType, any Error>?
    public var executeTime: Date?
    public var finishTime: Date?
    private let stateQueue = DispatchQueue(label: "XYCmd.state", attributes: .concurrent)
    private var _state: XYState = .idle {
        didSet {
            XYLog.info(id: id, tag: [logTag, "state"], content: "\(oldValue) → \(_state)")
        }
    }
    public var state: XYState {
        get {
            return stateQueue.sync { _state }
        }
        set {
            stateQueue.async(flags: .barrier) {
                let oldValue = self._state
                self._state = newValue
                // 状态变化日志
                XYLog.info(id: self.id, tag: [self.logTag, "state"], content: "\(oldValue) → \(newValue)")
            }
        }
    }
    
    // MARK: timeout
    public let timeout: TimeInterval
    
    // MARK: retry
    public let maxRetries: Int?
    public var curRetries: Int = 0
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
            return try await executeImp()
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
    
    private func executeImp() async throws -> ResultType {
        let tag = [logTag, "execute"]
        
        // 初始化执行
        state = .executing
        executeTime = Date()
        curRetries = 0
        
        // 重试循环
        while true {
            do {
                // 执行前检查取消状态
                if isCancelled() {
                    let finalError = XYError.cancelled
                    finishExecution(tag: tag, state: .cancelled, result: nil, error: finalError)
                    onDidExecute?(.failure(finalError))
                    throw finalError
                }
                
                let result = try await executeWithTimeout()
                
                // 执行后检查取消状态
                if isCancelled() {
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
                if isCancelled() {
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
                    if isCancelled() {
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

