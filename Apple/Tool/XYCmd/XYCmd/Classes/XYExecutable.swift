//
//  XYExecutable.swift
//  XYCmd
//
//  Created by hsf on 2025/10/3.
//

// MARK: - Import
// System
import Foundation
// Basic
// Service
import XYLog
// Tool
// Business
// Third


// MARK: - XYExecutable
public protocol XYExecutable {
    associatedtype ResultType
    
    // MARK: identifier
    /// 唯一标识
    var id: String { get }
    
    // MARK: execution
    /// 执行任务
    var executeTask: Task<ResultType, any Error>? { get }
    /// 执行状态
    var state: XYState { get }
    
    // MARK: time
    /// 执行开始时间
    var executeTime: Date? { get }
    /// 执行结束时间
    var finishTime: Date? { get }
    
    // MARK: timeout
    /// 超时时间
    var timeout: TimeInterval? { get }
    
    // MARK: retry
    /// 最大重试次数
    var maxRetries: Int? { get }
    /// 当前重试次数
    var curRetries: Int { get }
    /// 重试延时时间
    var retryDelay: TimeInterval? { get }
    
    // MARK: hook var
    /// 即将执行
    var onStateDidChanged: ((XYState, XYState) -> Void)? { get }
    /// 即将执行
    var onWillExecute: (() -> Void)? { get }
    /// 超时
    var onDidTimeout: (() -> Void)? { get }
    /// 取消执行
    var onDidCancelExecute: (() -> Void)? { get }
    /// 执行完成
    var onDidExecute: ((Result<ResultType, any Error>) -> Void)? { get }
    /// 重试
    var onDidRetry: ((Int, Error?) -> Void)? { get }
    
    // MARK: hook func
    /// 即将执行
    func stateDidChanged(oldValue: XYState, newValue: XYState)
    /// 即将执行
    func willExecute()
    /// 超时
    func didTimeout()
    /// 取消执行
    func didCancelExecute()
    /// 执行完成
    func didExecute(result: Result<ResultType, any Error>)
    /// 重试
    func didRetry(index: Int, error: Error?)
    
    // MARK: func
    /// 执行
    @discardableResult func execute() async throws -> ResultType
    /// 取消
    func cancel()
    /// 重置
    func reset()
    /// 重试
    @discardableResult func retry() async throws -> ResultType
    /// 判断错误是否可重试
    func checkErrorRetryEnable(error: Error) -> Bool 
}


// MARK: - Error
extension XYExecutable {
    /// 标准化错误为 XYError（安全处理 nil）
    public static func normalizeError(_ error: Error?) -> XYError {
        if let err = error as? XYError {
            return err
        }
        return XYError.other(error)
    }
}


// MARK: - Timeout
extension XYExecutable {
    /// 带超时的异步操作包装
    public func withTimeout<T>(_ seconds: TimeInterval?,
                               operation: @escaping () async throws -> T) async throws -> T {
        guard let seconds = seconds, seconds > 0 else {
            return try await operation()
        }
        
        return try await withThrowingTaskGroup(of: T.self) { group in
            let operationTask = group.addTaskUnlessCancelled {
                return try await operation()
            }
            guard operationTask != nil else {
                throw XYError.cancelled
            }
            let timeoutTask = group.addTaskUnlessCancelled {
                try await Task.sleep(seconds: seconds)
                didTimeout()
                throw XYError.timeout
            }
            guard timeoutTask != nil else {
                throw XYError.cancelled
            }
            do {
                if let result = try await group.next() {
                    group.cancelAll()
                    return result
                } else {
                    group.cancelAll()
                    let fallbackError = NSError(
                        domain: "XYCmd",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Timeout task group returned no result"]
                    )
                    throw XYError.other(fallbackError)
                }
            } catch {
                group.cancelAll()
                if state == .cancelled || Task.isCancelled {
                    throw XYError.cancelled
                }
                throw error
            }
        }
    }
}
