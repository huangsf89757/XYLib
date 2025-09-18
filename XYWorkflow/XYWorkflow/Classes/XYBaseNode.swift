//
//  XYBaseNode.swift
//  Pods
//
//  Created by hsf on 2025/9/16.
//

import Foundation
import XYLog

// MARK: - XYBaseNode
open class XYBaseNode: XYNode<Any?> {
    // MARK: var
    /// 当前异步操作的 Continuation，用于在异步操作完成时恢复
    private var continuation: CheckedContinuation<Any?, Error>?
    /// 最大重试次数
    public let maxRetries: Int
    /// 当前已重试次数
    public private(set) var curRetries: Int = 0
    
    // MARK: init
    public init(id: String = UUID().uuidString,
                timeout: TimeInterval = 10,
                maxRetries: Int = 3) {
        self.maxRetries = maxRetries
        super.init(id: id, timeout: timeout)
        self.logTag = "Flow.N.B"
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
    
    /// 取消当前正在执行的命令。
    public override func cancel() {
        super.cancel()
        // 只有当 continuation 存在且未被 resume 时才触发取消
        if let continuation = self.continuation {
            self.continuation = nil
            continuation.resume(throwing: XYError.cancelled)
        }
    }
}


// MARK: - Private Helpers
private extension XYBaseNode {
    /// 设置超时任务。
    func startTimeoutTask() {
        let tag = [logTag, "timeout"]
        timeoutTask?.cancel()
        let task = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            XYLog.info(tag: tag, content: "did", "id=\(id)")
            self.finishExecution(with: .failure(XYError.timeout))
        }
        timeoutTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout, execute: task)
        XYLog.info(tag: tag, content: "start", "id=\(id)", "\(timeout)")
    }
    
    /// 执行单次命令（不含重试）
    private func executeOnce() async {
        do {
            executeTime = Date()
            let result = try await run()
            finishExecution(with: .success(result))
        } catch let error {
            finishExecution(with: .failure(error))
        }
    }
            
    /// 完成命令执行，无论是成功还是失败。
    func finishExecution(with result: Result<Any?, Error>) {
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
