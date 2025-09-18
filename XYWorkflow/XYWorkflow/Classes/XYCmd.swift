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
    public internal(set) var logTag = "Flow.C"
    
    // MARK: XYExecutable
    /// 唯一标识
    public let id: String
    /// 超时时间（秒）
    public let timeout: TimeInterval
    /// 用于管理超时和取消的 Task
    public internal(set) var timeoutTask: DispatchWorkItem?
    /// 命令运行状态
    public internal(set) var state: XYState = .idle {
        didSet {
            XYLog.info(tag: [logTag, "state"], content: "id=\(id)", "\(oldValue) → \(state)")
        }
    }
    /// 命令执行时间
    public internal(set) var executeTime: Date?
    
    // MARK: init
    public init(id: String, timeout: TimeInterval) {
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
}

