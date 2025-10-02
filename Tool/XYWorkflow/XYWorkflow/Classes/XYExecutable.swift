//
//  XYExecutable.swift
//  Pods
//
//  Created by hsf on 2025/9/16.
//

import Foundation
import XYUtil

// MARK: - XYExecutable
public protocol XYExecutable {
    /// 关联结果类型
    associatedtype ResultType
    
    // MARK: identifier
    /// 唯一标识
    var id: XYIdentifier { get }
    
    // MARK: execution
    /// 执行任务
    var executeTask: Task<ResultType, any Error>? { get }
    /// 执行开始时间
    var executeTime: Date? { get }
    /// 执行完成时间
    var finishTime: Date? { get }
    /// 执行状态
    var state: XYState { get }
    /// 执行内容（可选）
    var executionBlock: ((@escaping (Result<ResultType, Error>) -> Void) -> Void)? { get }
    
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
