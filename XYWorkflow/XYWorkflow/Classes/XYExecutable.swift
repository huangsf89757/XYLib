//
//  XYExecutable.swift
//  Pods
//
//  Created by hsf on 2025/9/16.
//

import Foundation

// MARK: - XYExecutable
public protocol XYExecutable {
    /// 关联结果类型
    associatedtype ResultType
    /// 唯一标识
    var id: String { get }
    /// 执行状态
    var state: XYState { get }
    
    /// 命令开始时间
    var executeTime: Date? { get }
    /// 命令完成时间
    var finishTime: Date? { get }
    
    /// 超时时间（秒），<=0 表示无超时
    var timeout: TimeInterval { get }
    /// 最大重试次数。`nil` 或 `<= 0` 表示不重试。
    var maxRetries: Int? { get }
    /// 当前已重试次数
    var curRetries: Int { get }
    /// 重试之间的延迟（秒）
    var retryDelay: TimeInterval? { get }
    
    /// 命令执行内容
    var executionBlock: ((@escaping (Result<ResultType, Error>) -> Void) -> Void)? { get }
    /// 执行函数
    func execute() async throws -> ResultType
    /// 取消执行
    func cancel()
}
