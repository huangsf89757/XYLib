////
////  XYBaseNode.swift
////  Pods
////
////  Created by hsf on 2025/9/16.
////
//
//import Foundation
//import XYLog
//
//// MARK: - XYBaseNode
//open class XYBaseNode<ResultType>: XYNode<ResultType> {
//    // MARK: var
//    /// 当前异步操作的 Continuation，用于在异步操作完成时恢复
//    private var continuation: CheckedContinuation<ResultType, Error>?
//    
//    // 用于存储闭包的属性
//    private var executionBlock: ((@escaping (Result<ResultType, Error>) -> Void) -> Void)?
//    
//    // MARK: init
//    public init(id: String = UUID().uuidString,
//                timeout: TimeInterval = 10,
//                maxRetries: Int = 3) {
//        super.init(id: id, timeout: timeout, maxRetries: maxRetries)
//        self.logTag = "WorkFlow.Node.Base"
//    }
//    
//    /// 便利构造器，支持使用闭包直接创建节点
//    public convenience init(id: String = UUID().uuidString,
//                            timeout: TimeInterval = 10,
//                            maxRetries: Int = 3,
//                            executionBlock: @escaping (@escaping (Result<ResultType, Error>) -> Void) -> Void) {
//        self.init(id: id, timeout: timeout, maxRetries: maxRetries)
//        self.executionBlock = executionBlock
//    }
//    
//    // MARK: override
//    public override func run() async throws -> ResultType {
//        let tag = [logTag, "execute"]
//        XYLog.info(tag: tag, process: .begin, content: "id=\(id)")
//        executeTime = Date()
//        let result: ResultType
//        // 如果提供了闭包，则执行闭包
//        if let executionBlock = self.executionBlock {
//            let tag = [logTag, "runOnce"]
//            XYLog.info(tag: tag, process: .doing, content: "executionBlock")
//            result = try await withCheckedThrowingContinuation { continuation in
//                executionBlock { result in
//                    switch result {
//                    case .success(let value):
//                        continuation.resume(returning: value)
//                    case .failure(let error):
//                        continuation.resume(throwing: error)
//                    }
//                }
//            }
//        } else {
//            // 否则调用子类实现的runOnce方法
//            result = try await runOnce()
//        }
//        var durationInfo = ""
//        if let duration = executeTime.map({ Date().timeIntervalSince($0) }) {
//            durationInfo = String(format: "duration=%.2fs", duration)
//        }
//        XYLog.info(tag: tag, process: .succ, content: durationInfo)
//        return result
//    }
//    
//    /// 子类需要实现的单次执行方法
//    /// 注意：此方法不应被直接调用，应通过execute()方法触发执行
//    open func runOnce() async throws -> ResultType {
//        let tag = [logTag, "runOnce"]
//        let error = XYError.notImplemented
//        XYLog.info(tag: tag, process: .fail(error.info))
//        throw error
//    }
//    
//    /// 取消当前正在执行的命令。
//    public override func cancel() {
//        super.cancel()
//    }
//}
//
//
//// MARK: - Private Helpers
//private extension XYBaseNode {
//   
//    /// 执行单次命令（不含重试）
//    func executeOnce() async {
//        do {
//            executeTime = Date()
//            let result: ResultType
//            // 如果提供了闭包，则执行闭包
//            if let executionBlock = self.executionBlock {
//                let tag = [logTag, "runOnce"]
//                XYLog.info(tag: tag, process: .doing, content: "executionBlock")
//                result = try await withCheckedThrowingContinuation { continuation in
//                    executionBlock { result in
//                        switch result {
//                        case .success(let value):
//                            continuation.resume(returning: value)
//                        case .failure(let error):
//                            continuation.resume(throwing: error)
//                        }
//                    }
//                }
//            } else {
//                // 否则调用子类实现的runOnce方法
//                result = try await runOnce()
//            }
//            finishExecution(with: .success(result))
//        } catch let error {
//            finishExecution(with: .failure(error))
//        }
//    }
//            
//    /// 完成命令执行，无论是成功还是失败。
//    func finishExecution(with result: Result<ResultType, Error>) {
//        let tag = [logTag, "execute"]
//        // 取消超时任务
//        timeoutTask?.cancel()
//        timeoutTask = nil
//        // 仅当 continuation 存在时才 resume（避免重复调用崩溃）
//        if let continuation = self.continuation {
//            self.continuation = nil
//            var durationInfo = ""
//            if let duration = executeTime.map({ Date().timeIntervalSince($0) }) {
//                durationInfo = String(format: "duration=%.2fs", duration)
//            }
//            
//            switch result {
//            case .success(let value):
//                state = .succeeded
//                XYLog.info(tag: tag, process: .succ, content: durationInfo)
//                continuation.resume(returning: value)
//            case .failure(let error):
//                var err: XYError
//                if let e = error as? XYError {
//                    err = e
//                } else {
//                    let e = XYError.unknown(error)
//                    err = e
//                }
//                state = .failed
//                XYLog.info(tag: tag, process: .fail(err.info), content: durationInfo)
//                continuation.resume(throwing: error)
//            }
//        }
//    }
//}
