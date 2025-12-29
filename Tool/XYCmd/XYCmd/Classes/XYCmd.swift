//
//  XYCmd.swift
//  XYCmd
//
//  Created by hsf on 2025/9/18.
//

// MARK: - Import
// System
import Foundation
// Basic
import XYExtension
// Server
import XYLog
// Tool
// Business
// Third


// MARK: - XYCmd
open class XYCmd<ResultType>: XYExecutable {
    // MARK: log
    public var logTag = "XYCmd"
    
    // MARK: identifier
    public let id: String
    
    // MARK: execution
    public internal(set) var executeTask: Task<ResultType, any Error>?
    public internal(set) var state: XYState = .idle {
        didSet {
            stateDidChanged(oldValue: oldValue, newValue: state)
        }
    }
    
    // MARK: time
    public internal(set) var executeTime: Date?
    public internal(set) var finishTime: Date?
    
    // MARK: timeout
    public let timeout: TimeInterval?
    
    // MARK: retry
    public let maxRetries: Int?
    public internal(set) var curRetries: Int = 0
    public let retryDelay: TimeInterval?
    
    // MARK: hook var
    public var onStateDidChanged: ((XYState, XYState) -> Void)?
    public var onWillExecute: (() -> Void)?
    public var onDidTimeout: (() -> Void)?
    public var onDidCancelExecute: (() -> Void)?
    public var onDidExecute: ((Result<ResultType, any Error>) -> Void)?
    public var onDidRetry: ((Int, Error?) -> Void)?
  
    // MARK: hook func
    open func stateDidChanged(oldValue: XYState, newValue: XYState) {
        onStateDidChanged?(oldValue, newValue)
        XYLog.info(id: id, tag: [logTag, "state"], content: "\(oldValue) → \(newValue)")
    }
    open func willExecute() {
        onWillExecute?()
    }
    open func didTimeout() {
        onDidTimeout?()
    }
    open func didCancelExecute() {
        onDidCancelExecute?()
    }
    open func didExecute(result: Result<ResultType, any Error>) {
        onDidExecute?(result)
    }
    open func didRetry(index: Int, error: Error?) {
        onDidRetry?(index, error)
    }
    
    // MARK: life cycle
    public init(id: String = UUID().uuidString,
                timeout: TimeInterval = 10,
                maxRetries: Int? = nil,
                retryDelay: TimeInterval? = nil) {
        self.id = id
        self.timeout = timeout
        self.maxRetries = maxRetries
        self.retryDelay = retryDelay
    }
    
    // MARK: execute
    /// 执行
    @discardableResult
    public final func execute() async throws -> ResultType {
        let tag = [logTag, "execute"]
        guard state == .idle else {
            let finalError = XYError.reject
            executeFailure(tag: tag, error: finalError)
            throw finalError
        }
        _reset()
        executeTime = Date()
        willExecute()
        XYLog.info(id: id, tag: tag, process: .begin)
        do {
            return try await _execute()
        } catch {
            throw error
        }
    }
    
    @discardableResult
    private func _execute() async throws -> ResultType {
        // 设置执行中状态
        state = .executing
        
        let executeTask = Task {
            return try await _executeImp()
        }
        self.executeTask = executeTask
        do {
            return try await executeTask.value
        } catch {
            // 如果任务被取消，确保状态正确设置
            if Task.isCancelled {
                state = .cancelled
            }
            throw error
        }
    }
    
    /// 执行实现
    private func _executeImp() async throws -> ResultType {
        let tag = [logTag, "execute"]
        // 重试循环
        var retryEnable = true
        while retryEnable {
            do {
                // 执行前检查
                try handleAbnormalIfNeeded(tag: tag)
                // 执行
                let result = try await withTimeout(timeout) { [weak self] in
                    guard let self = self else {
                        let finalError = XYError.zombie
                        throw finalError
                    }
                    return try await self.run()
                }
                // 执行后检查
                try handleAbnormalIfNeeded(tag: tag)
                // 执行结果
                executeSuccess(tag: tag, result: result)
                return result
            } catch let error {
                retryEnable = false
                XYLog.info(id: id, tag: tag, content: "error=\(error.localizedDescription)")
                try _retryEnable(tag: tag, error: error)
                if let retryDelay = retryDelay, retryDelay > 0 {
                    try await Task.sleep(seconds: retryDelay)
                }
                try handleAbnormalIfNeeded(tag: tag)
                _tagRetry(tag: tag, error: error)
                retryEnable = true
            }
        }
        let finalError = XYError.unexpected
        executeFailure(tag: tag, error: finalError)
        throw finalError
    }
    
    // MARK: run
    open func run() async throws -> ResultType {
        let tag = [logTag, "run"]
        let error = XYError.notImplemented
        XYLog.info(id: id, tag: tag, process: .fail, content:error.info)
        throw error
    }
    
    // MARK: cancel
    open func cancel() {
        // 只有在执行中或空闲状态可以取消
        guard state == .executing || state == .idle else {
            return
        }
        let tag = [logTag, "cancel"]
        XYLog.info(id: id, tag: tag)
        
        // 保存当前状态
        let currentState = state
        
        // 取消执行任务
        executeTask?.cancel()
        
        // 更新状态为已取消
        state = .cancelled
        
        // 取消
        didCancelExecute()
        
        // 如果是在执行中，完成执行
        if currentState == .executing {
            executeFailure(tag: tag, error: XYError.cancelled)
        }
    }
    
    // MARK: reset
    open func reset() {
        let tag = [logTag, "reset"]
        XYLog.info(id: id, tag: tag)
        _reset()
    }
    private func _reset() {
        state = .idle
        curRetries = 0
        executeTime = nil
        executeTask = nil
    }
    
    // MARK: retry
    /// 重试
    @discardableResult
    open func retry() async throws -> ResultType  {
        let tag = [logTag, "retry"]
        try _retryEnable(tag: tag, error: nil)
        _tagRetry(tag: tag, error: nil)
        return try await _execute()
    }
    /// 是否可重试
    private func _retryEnable(tag: [String], error: Error?) throws {
        // 判断是否支持重试
        guard let maxRetries = self.maxRetries, maxRetries > 0 else {
            let finalError = XYError.retryDisable
            executeFailure(tag: tag, error: finalError)
            throw finalError
        }
        // 判断当前错误是否可重试
        if let error = error {
            guard checkErrorRetryEnable(error: error) else {
                let finalError = XYError.cannotRetryError
                executeFailure(tag: tag, error: finalError)
                throw finalError
            }
        }
        // 超出最大重试次数？
        if curRetries >= maxRetries {
            let finalError = XYError.maxRetryExceeded
            executeFailure(tag: tag, error: finalError)
            throw finalError
        }
    }
    /// 标记重试
    private func _tagRetry(tag: [String], error: Error?)  {
        curRetries += 1
        didRetry(index: curRetries, error: error)
        if let error = error {
            XYLog.info(id: id, tag: tag, content: "retry=\(curRetries)/\(maxRetries)", "error=\(error.localizedDescription)")
        } else {
            XYLog.info(id: id, tag: tag, content: "retry=\(curRetries)/\(maxRetries)")
        }
    }
    /// 判断错误是否可重试
    open func checkErrorRetryEnable(error: Error) -> Bool {
        if let err = error as? XYError {
            switch err {
            case .timeout, .other:
                return true
            default:
                return false
            }
        }
        return false
    }
}


// MARK: - Execute
extension XYCmd {
    /// 执行成功
    func executeSuccess(tag: [String], result: ResultType) {
        guard let content = _finishExecution(state: .succeeded) else { return }
        XYLog.info(id: id, tag: tag, process: .succ, content: content)
        didExecute(result: .success(result))
    }
    /// 执行失败
    func executeFailure(tag: [String], error: Error) {
        guard let content = _finishExecution(state: .failed) else { return }
        let err = Self.normalizeError(error)
        XYLog.info(id: id, tag: tag, process: .fail, content: content, "error=\(err.info)")
        didExecute(result: .failure(err))
    }
    /// 执行结果
    private func _finishExecution(state: XYState) -> String? {
        executeTask?.cancel()
        executeTask = nil
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
        return durationInfo
    }
    /// 异常处理
    func handleAbnormalIfNeeded(tag: [String]) throws {
        switch state {
        case .cancelled:
            let finalError = XYError.cancelled
            executeFailure(tag: tag, error: finalError)
            throw finalError
        default:
            return
        }
    }
}
