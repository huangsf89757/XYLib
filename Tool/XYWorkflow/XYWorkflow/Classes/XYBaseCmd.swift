//
//  XYBaseCmd.swift
//  XYWorkflow
//
//  Created by hsf on 2025/9/18.
//

import Foundation
import XYUtil
import XYExtension
import XYLog

// MARK: - XYBaseCmd
open class XYBaseCmd<ResultType>: XYCmd<ResultType> {
    
    // MARK: var
    public let executionBlock: ((@escaping (Result<ResultType, Error>) -> Void) -> Void)?
    /// 在group中是否允许失败
    public var allowsFailureInGroup: Bool = true
    
    // MARK: init
    public init(id: XYIdentifier = UUID().uuidString,
                timeout: TimeInterval = 10,
                maxRetries: Int? = nil,
                retryDelay: TimeInterval? = nil,
                executionBlock: ((@escaping (Result<ResultType, Error>) -> Void) -> Void)? = nil) {
        self.executionBlock = executionBlock
        super.init(id: id, timeout: timeout, maxRetries: maxRetries, retryDelay: retryDelay)
        self.logTag = "WorkFlow.BaseCmd"
    }
    
    // MARK: run
    open override func run() async throws -> ResultType {
        let result: ResultType
        // 包装执行逻辑（含超时）
        if let block = executionBlock {
            result = try await withCheckedThrowingContinuation { [weak self] continuation in
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
        } else {
            result = try await super.run()
        }
        return result
    }
}

