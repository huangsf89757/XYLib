//
//  XYBaseNode.swift
//  Pods
//
//  Created by hsf on 2025/9/16.
//

import Foundation
import XYLog

// MARK: - XYBaseNode
open class XYBaseNode<ResultType>: XYNode<ResultType> {
    // MARK: var
    /// 当前异步操作的 Continuation，用于在异步操作完成时恢复
    private var continuation: CheckedContinuation<ResultType, Error>?
    /// 最大重试次数
    public let maxRetries: Int
    /// 当前已重试次数
    public private(set) var curRetries: Int = 0
    
    // 用于存储闭包的属性
    private var executionBlock: ((@escaping (Result<ResultType, Error>) -> Void) -> Void)?
    
    // MARK: init
    public init(id: String = UUID().uuidString,
                timeout: TimeInterval = 10,
                maxRetries: Int = 3) {
        self.maxRetries = maxRetries
        super.init(id: id, timeout: timeout)
        self.logTag = "WorkFlow.Node.Base"
    }
    
    /// 便利构造器，支持使用闭包直接创建节点
    public convenience init(id: String = UUID().uuidString,
                            timeout: TimeInterval = 10,
                            maxRetries: Int = 3,
                            executionBlock: @escaping (@escaping (Result<ResultType, Error>) -> Void) -> Void) {
        self.init(id: id, timeout: timeout, maxRetries: maxRetries)
        self.executionBlock = executionBlock
    }
    
    // MARK: override
    public override func run() async throws -> ResultType {
        let tag = [logTag, "execute"]
        XYLog.info(tag: tag, process: .begin, content: "id=\(id)")
        curRetries = 0 // 重置重试计数器
        while true {
            do {
                return try await withCheckedThrowingContinuation { continuation in
                    self.continuation = continuation
                    self.startTimeoutTask()
                    Task {
                        await self.executeOnce()
                    }
                }
            } catch let error {
                // 如果已取消，不重试
                if state == .cancelled {
                    let err = XYError.cancelled
                    XYLog.info(tag: tag, process: .fail(err.info))
                    throw err
                }
                // 如果超出最大重试次数，不重试
                if curRetries >= maxRetries {
                    let err = XYError.maxRetryExceeded
                    XYLog.info(tag: tag, process: .fail(err.info))
                    throw err
                }
                // 可根据错误类型决定是否重试（示例：超时和未知错误可重试）
                if let err = error as? XYError {
                    switch err {
                    case .timeout, .other:
                        XYLog.info(tag: tag, process: .fail(err.info), content: "\(curRetries)/\(maxRetries)")
                        curRetries += 1
                        continue // 重试
                    default:
                        XYLog.info(tag: tag, process: .fail(err.info))
                        throw err
                    }
                } else {
                    let err = XYError.unknown(error)
                    XYLog.info(tag: tag, process: .fail(err.info))
                    throw err
                }
            }
        }
    }
    
    /// 子类需要实现的单次执行方法
    /// 注意：此方法不应被直接调用，应通过execute()方法触发执行
    open func runOnce() async throws -> ResultType {
        let tag = [logTag, "runOnce"]
        let error = XYError.notImplemented
        XYLog.info(tag: tag, process: .fail(error.info))
        throw error
    }
    
    /// 取消当前正在执行的命令。
    public override func cancel() {
        super.cancel()
        // 只有当 continuation 存在且未被 resume 时才触发取消
        if let continuation = self.continuation {
            self.continuation = nil
            continuation.resume(throwing: XYError.cancelled)
        }
    }
    
    /// 重写startTimeoutTask方法以处理超时
    internal override func startTimeoutTask() {
        guard timeout > 0 else { return }
        let tag = [logTag, "timeout"]
        // Cancel previous timeout if any
        timeoutTask?.cancel()
        let task = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                guard let self = self else { return }
                XYLog.info(tag: tag, content: "did", "id=\(self.id)")
                // 超时时设置状态为失败并抛出timeout错误
                self.state = .failed
                if let continuation = self.continuation {
                    self.continuation = nil
                    continuation.resume(throwing: XYError.timeout)
                }
            } catch {
                // Task was cancelled; nothing to do
            }
        }
        timeoutTask = task
        XYLog.info(tag: tag, content: "start", "id=\(id)", "\(timeout)s")
    }
}


// MARK: - Private Helpers
private extension XYBaseNode {
   
    /// 执行单次命令（不含重试）
    func executeOnce() async {
        do {
            executeTime = Date()
            let result: ResultType
            // 如果提供了闭包，则执行闭包
            if let executionBlock = self.executionBlock {
                let tag = [logTag, "runOnce"]
                XYLog.info(tag: tag, process: .doing, content: "executionBlock")
                result = try await withCheckedThrowingContinuation { continuation in
                    executionBlock { result in
                        switch result {
                        case .success(let value):
                            continuation.resume(returning: value)
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                }
            } else {
                // 否则调用子类实现的runOnce方法
                result = try await runOnce()
            }
            finishExecution(with: .success(result))
        } catch let error {
            finishExecution(with: .failure(error))
        }
    }
            
    /// 完成命令执行，无论是成功还是失败。
    func finishExecution(with result: Result<ResultType, Error>) {
        let tag = [logTag, "execute"]
        // 取消超时任务
        timeoutTask?.cancel()
        timeoutTask = nil
        // 仅当 continuation 存在时才 resume（避免重复调用崩溃）
        if let continuation = self.continuation {
            self.continuation = nil
            var durationInfo = ""
            if let duration = executeTime.map({ Date().timeIntervalSince($0) }) {
                durationInfo = String(format: "duration=%.2fs", duration)
            }
            
            switch result {
            case .success(let value):
                state = .succeeded
                XYLog.info(tag: tag, process: .succ, content: durationInfo)
                continuation.resume(returning: value)
            case .failure(let error):
                var err: XYError
                if let e = error as? XYError {
                    err = e
                } else {
                    let e = XYError.unknown(error)
                    err = e
                }
                state = .failed
                XYLog.info(tag: tag, process: .fail(err.info), content: durationInfo)
                continuation.resume(throwing: error)
            }
        }
    }
}