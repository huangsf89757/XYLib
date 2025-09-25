//
//  XYCmd.swift
//  Pods
//
//  Created by hsf on 2025/9/18.
//

import Foundation
import XYLog

// MARK: - XYCmd
open class XYCmd<ResultType>: XYExecutable {
    // MARK: log
    public internal(set) var logTag = "WorkFlow.Cmd"
    
    // MARK: XYExecutable
    /// 唯一标识
    public let id: String
    /// 超时时间（秒）
    public let timeout: TimeInterval
    /// 用于管理超时和取消的 Task（Swift Concurrency）
    public internal(set) var timeoutTask: Task<Void, Never>?
    /// 命令运行状态
    public internal(set) var state: XYState = .idle {
        didSet {
            XYLog.info(tag: [logTag, "state"], content: "id=\(id)", "\(oldValue) → \(state)")
        }
    }
    /// 命令执行时间
    public internal(set) var executeTime: Date?
    
    /// 最大重试次数
    public let maxRetries: Int
    /// 当前已重试次数
    public private(set) var curRetries: Int = 0
    
    // MARK: init
    public init(id: String = UUID().uuidString,
                timeout: TimeInterval = 10,
                maxRetries: Int = 0) {
        self.id = id
        self.timeout = timeout
        self.maxRetries = maxRetries
        self.curRetries = 0
    }
    
    // MARK: func
    /// 执行函数
    @discardableResult
    public final func execute() async throws -> ResultType {
        let tag = [logTag, "execute"]
        XYLog.info(tag: tag, process: .begin, content: "id=\(id)")
        if state == .cancelled {
            let err = XYError.cancelled
            XYLog.info(tag: tag, process: .fail(err.info))
            throw err
        }
        if state == .executing {
            let err = XYError.executing
            XYLog.info(tag: tag, process: .fail(err.info))
            throw err
        }
        state = .executing
        executeTime = Date()
        
        // 重置重试计数器
        curRetries = 0
        
        while true {
            do {
                return try await withCheckedThrowingContinuation { continuation in
                    self.continuation = continuation
                    self.startTimeoutTask()
                    Task {
                        do {
                            let result = try await self.run()
                            // 正常完成时清理超时任务
                            self.timeoutTask?.cancel()
                            self.timeoutTask = nil
                            // 确保continuation没有被超时处理使用过
                            if let cont = self.continuation {
                                self.continuation = nil
                                cont.resume(returning: result)
                            }
                        } catch let error {
                            // 出错时清理超时任务
                            self.timeoutTask?.cancel()
                            self.timeoutTask = nil
                            // 确保continuation没有被超时处理使用过
                            if let cont = self.continuation {
                                self.continuation = nil
                                cont.resume(throwing: error)
                            }
                        }
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
                if maxRetries > 0, curRetries >= maxRetries {
                    let err = XYError.maxRetryExceeded
                    XYLog.info(tag: tag, process: .fail(err.info))
                    throw err
                }
                // 可根据错误类型决定是否重试（示例：超时和未知错误可重试）
                if let err = error as? XYError {
                    switch err {
                    case .timeout, .other:
                        if maxRetries > 0 {
                            XYLog.info(tag: tag, process: .fail(err.info), content: "\(curRetries)/\(maxRetries)")
                            curRetries += 1
                            continue // 重试
                        } else {
                            XYLog.info(tag: tag, process: .fail(err.info))
                            throw err
                        }
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
    
    /// 开始执行
    open func run() async throws -> ResultType {
        let tag = [logTag, "execute"]
        let error = XYError.notImplemented
        XYLog.info(tag: tag, process: .fail(error.info))
        throw error
    }
    
    /// 取消执行
    open func cancel() {
        let tag = [logTag, "cancel"]
        state = .cancelled
        XYLog.info(tag: tag, content: "id=\(id)")
        timeoutTask?.cancel()
        timeoutTask = nil
        // 只有当 continuation 存在且未被 resume 时才触发取消
        if let continuation = self.continuation {
            self.continuation = nil
            continuation.resume(throwing: XYError.cancelled)
        }
    }
    
    internal func startTimeoutTask() {
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
    
    // 添加continuation属性以支持超时处理
    private var continuation: CheckedContinuation<ResultType, Error>?
}