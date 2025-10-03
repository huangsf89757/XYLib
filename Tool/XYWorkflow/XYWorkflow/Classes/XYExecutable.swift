//
//  XYExecutable.swift
//  XYWorkflow
//
//  Created by hsf on 2025/10/3.
//

import Foundation
import XYUtil
import XYLog

// MARK: - XYExecutable
public protocol XYExecutable {
    associatedtype ResultType
    
    // MARK: identifier
    
    /// 唯一标识
    var id: XYIdentifier { get }
    
    // MARK: execution
    
    /// 执行任务
    var executeTask: Task<ResultType, any Error>? { get }
    
    /// 执行开始时间
    var executeTime: Date? { get }
    
    /// 执行结束时间
    var finishTime: Date? { get }
    
    /// 执行状态
    var state: XYState { get }
    
    // MARK: timeout
    
    /// 超时时间
    var timeout: TimeInterval { get }
    
    // MARK: retry
    
    /// 最大重试次数
    var maxRetries: Int? { get }
    
    /// 当前重试次数
    var curRetries: Int { get }
    
    /// 重试延时时间
    var retryDelay: TimeInterval? { get }
    
    // MARK: hock
    
    /// 即将执行
    var onWillExecute: (() -> Void)? { get }
    
    /// 执行完成
    var onDidExecute: ((Result<ResultType, any Error>) -> Void)? { get }
    
    /// 重试
    var onRetry: ((Error, Int) -> Void)? { get }
    
    // MARK: func
    
    /// 开始执行
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
        return state == .succeeded || state == .failed || state == .cancelled
    }
    
    /// 当前执行是否已取消
    public var isCancelled: Bool {
        return state == .cancelled
    }
}

// MARK: Error
extension XYExecutable {
    /// 标准化错误为 XYError（安全处理 nil）
    public func normalizeError(_ error: Error?) -> XYError {
        if let err = error as? XYError {
            return err
        }
        return XYError.other(error)
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
                    throw XYError.other(fallbackError)
                }
            } catch {
                // 取消所有任务并重新抛出错误
                group.cancelAll()
                
                // 检查是否是由于取消导致的错误
                if self.isCancelled || Task.isCancelled {
                    throw XYError.cancelled
                }
                
                throw error
            }
        }
    }
}
