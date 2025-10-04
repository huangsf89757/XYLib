//
//  XYBaseCmd.swift
//  XYCmd
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
    private var continuation: CheckedContinuation<ResultType, any Error>?
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
        // 如果有执行块，直接执行它，否则调用父类实现
        guard let block = executionBlock else {
            return try await super.run()
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            block { [weak self] result in
                guard let self = self else { return }
                guard !self.isCompleted else { return }
                
                switch result {
                case .success(let value):
                    continuation.resume(returning: value)
                case .failure(let error):
                    // 统一错误处理
                    let normalizedError = self.normalizeError(error)
                    continuation.resume(throwing: normalizedError)
                }
            }
        }
    }
    
    // MARK: cancel
    open override func cancel() {
        super.cancel()
        self.continuation?.resume(throwing: XYError.cancelled)
    }
}

