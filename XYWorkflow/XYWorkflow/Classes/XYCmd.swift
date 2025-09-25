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
    
    // MARK: init
    public init(id: String = UUID().uuidString,
                timeout: TimeInterval = 10) {
        self.id = id
        self.timeout = timeout
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
        do {
            let result = try await run()
            return result
        } catch {
            throw error
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

// 扩展XYCmd以支持超时处理
private extension XYCmd {
    /// 为超时处理提供带continuation的execute方法
    func executeWithContinuation() async throws -> ResultType {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            Task {
                do {
                    self.startTimeoutTask()
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
    }
}