//
//  XYWorkflow.swift
//  Pods
//
//  Created by hsf on 2025/9/16.
//

import Foundation
import XYLog


// MARK: - XYWork
open class XYWorkflow<ResultType>: XYCmd<ResultType> {
    public let root: XYNode<ResultType>
    public init(id: String = UUID().uuidString,
                timeout: TimeInterval = 10,
                root: XYNode<ResultType>) {
        self.root = root
        super.init(id: id, timeout: timeout)
        self.logTag = "WorkFlow.Work"
    }
    
    // MARK: - 执行工作流
    /// 从根节点开始执行整个工作流直到结束
    open override func run() async throws -> ResultType {
        let tag = [logTag, "execute"]
        XYLog.info(tag: tag, process: .begin, content: "id=\(id)")
        startTimeoutTask()
        do {
            let result = try await executeFromNode(root)
            XYLog.info(tag: tag, process: .succ, content: "id=\(id)")
            return result
        } catch {
            XYLog.info(tag: tag, process: .fail(error.localizedDescription), content: "id=\(id)")
            throw error
        }
    }
    
    /// 递归执行节点及其后续节点
    private func executeFromNode(_ node: XYNode<ResultType>) async throws -> ResultType {
        let tag = [logTag, "executeNode"]
        XYLog.debug(tag: tag, content: "Executing node id=\(node.id)")
        let result = try await node.execute()
        if let nextNode = node.next {
            XYLog.debug(tag: tag, content: "Moving to next node id=\(nextNode.id)")
            return try await executeFromNode(nextNode)
        }
        XYLog.debug(tag: tag, content: "Reached end of workflow")
        return result
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
                // 超时时设置状态为失败
                self.state = .failed
                // 取消根节点
                self.root.cancel()
            } catch {
                // Task was cancelled; nothing to do
            }
        }
        timeoutTask = task
        XYLog.info(tag: tag, content: "start", "id=\(id)", "\(timeout)s")
    }
}