////
////  XYWorkflow.swift
////  XYWorkflow
////
////  Created by hsf on 2025/9/16.
////
//
//import Foundation
//import XYLog
//
//
//// MARK: - XYWork
//open class XYWorkflow<ResultType>: XYCmd<ResultType> {
//    public let root: XYNode<ResultType>
//    public init(id: String = UUID().uuidString,
//                timeout: TimeInterval = 10,
//                maxRetries: Int = 0,
//                root: XYNode<ResultType>) {
//        self.root = root
//        super.init(id: id, timeout: timeout, maxRetries: maxRetries)
//        self.logTag = "WorkFlow.Work"
//    }
//    
//    // MARK: - 执行工作流
//    /// 从根节点开始执行整个工作流直到结束
//    open override func run() async throws -> ResultType {
//        let tag = [logTag, "execute"]
//        XYLog.info(tag: tag, process: .begin, content: "id=\(id)")
//        do {
//            let result = try await executeFromNode(root)
//            XYLog.info(tag: tag, process: .succ, content: "id=\(id)")
//            return result
//        } catch {
//            XYLog.info(tag: tag, process: .fail(error.localizedDescription), content: "id=\(id)")
//            throw error
//        }
//    }
//    
//    /// 递归执行节点及其后续节点
//    private func executeFromNode(_ node: XYNode<ResultType>) async throws -> ResultType {
//        let tag = [logTag, "executeNode"]
//        XYLog.debug(tag: tag, content: "Executing node id=\(node.id)")
//        let result = try await node.execute()
//        if let nextNode = node.next {
//            XYLog.debug(tag: tag, content: "Moving to next node id=\(nextNode.id)")
//            return try await executeFromNode(nextNode)
//        }
//        XYLog.debug(tag: tag, content: "Reached end of workflow")
//        return result
//    }
//    
//}
