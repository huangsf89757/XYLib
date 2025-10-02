//
//  XYExecutable.swift
//  XYWorkflow
//
//  Created by hsf on 2025/9/16.
//

import Foundation
import XYUtil
import XYLog

// MARK: - XYExecutable
public protocol XYExecutable: AnyObject {
    /// 关联结果类型
    associatedtype ResultType
    
    // MARK: identifier
    /// 唯一标识
    var id: XYIdentifier { get }
    
    // MARK: execution
    /// 执行任务
    var executeTask: Task<ResultType, any Error>? { get }
    /// 执行开始时间
    var executeTime: Date? { get set }
    /// 执行完成时间
    var finishTime: Date? { get set }
    /// 执行状态
    var state: XYState { set get }
    
    // MARK: timeout
    /// 超时时间（秒），<=0 表示无超时
    var timeout: TimeInterval { get }
    
    // MARK: retry
    /// 最大重试次数。`nil` 或 `<= 0` 表示不重试。
    var maxRetries: Int? { get }
    /// 当前已重试次数
    var curRetries: Int { get }
    /// 重试之间的延迟（秒）
    var retryDelay: TimeInterval? { get }
    
    // MARK: hock
    /// 即将执行
    var onWillExecute: (() -> Void)? { get }
    /// 执行结束
    var onDidExecute: ((Result<ResultType, Error>) -> Void)? { get }
    /// 重试
    var onRetry: ((Error, Int) -> Void)? { get }
    
    // MARK: func
    /// 执行函数
    func execute() async throws -> ResultType
    /// 取消执行
    func cancel()
}

// MARK: - State
extension XYExecutable {
    /// 是否正在执行
    public var isExecuting: Bool {
        return state == .executing
    }
    
    /// 是否已完成
    public var isCompleted: Bool {
        return state == .succeeded || state == .failed
    }
}

// MARK: Execute
extension XYExecutable {
    /// 当前执行是否已取消
    public func isCancelled() -> Bool {
        return state == .cancelled || Task.isCancelled
    }
        
    /// 完成执行（更新状态、时间、日志）
    public func finishExecution(tag: [String], state: XYState, result: ResultType?, error: Error?) {
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
extension XYExecutable {
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
extension XYExecutable {
    /// 带超时的异步操作包装
    public func withTimeout<T>(_ seconds: TimeInterval,
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
                domain: "XYWorkflow",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Timeout task group returned no result"]
            )
            throw XYError.unknown(fallbackError)
        }
    }
}
