import XCTest
import XYExtension
@testable import XYWorkflow

final class XYBaseNodeTests: XCTestCase {
    
    /// 测试基础节点成功执行的情况
    /// 验证节点能够正确执行并返回预期结果
    func testBaseNodeSuccess() async throws {
        final class SuccessNode: XYBaseNode<String> {
            override func runOnce() async throws -> String {
                return "success"
            }
        }
        
        let node = SuccessNode()
        let result = try await node.execute()
        XCTAssertEqual(result, "success")
        XCTAssertEqual(node.state, .succeeded)
    }
    
    /// 测试基础节点执行失败的情况
    /// 验证节点在执行失败时能够正确处理错误
    func testBaseNodeFailure() async throws {
        final class FailureNode: XYBaseNode<String> {
            override func runOnce() async throws -> String {
                throw XYError.unknown(NSError(domain: "Test", code: 0, userInfo: nil))
            }
        }
        
        let node = FailureNode()
        do {
            _ = try await node.execute()
            XCTFail("Expected error to be thrown")
        } catch is XYError {
            XCTAssertEqual(node.state, .failed)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    /// 测试基础节点超时的情况
    /// 验证节点在执行超时时能够正确处理并抛出timeout错误
    func testBaseNodeTimeout() async throws {
        final class TimeoutNode: XYBaseNode<String> {
            let executionTime: TimeInterval
            
            init(timeout: TimeInterval, executionTime: TimeInterval = 1.0) {
                self.executionTime = executionTime
                super.init(timeout: timeout, maxRetries: 0) // 不重试
            }
            
            override func runOnce() async throws -> String {
                try await Task.sleep(seconds: executionTime)
                return "done"
            }
        }
        
        let node = TimeoutNode(timeout: 0.1, executionTime: 1.0)
        
        do {
            _ = try await node.execute()
            XCTFail("Expected timeout error to be thrown")
        } catch let error as XYError {
            XCTAssertEqual(error, XYError.timeout)
            XCTAssertEqual(node.state, .failed)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    /// 测试基础节点重试机制成功的情况
    /// 验证节点在前几次执行失败后能够自动重试，并在成功后返回结果
    func testBaseNodeRetrySuccess() async throws {
        final class RetrySuccessNode: XYBaseNode<String> {
            var attemptCount = 0
            
            override func runOnce() async throws -> String {
                attemptCount += 1
                if attemptCount < 3 {
                    throw XYError.other(NSError(domain: "Test", code: 0, userInfo: nil))
                }
                return "success on attempt \(attemptCount)"
            }
        }
        
        let node = RetrySuccessNode()
        let result = try await node.execute()
        XCTAssertEqual(result, "success on attempt 3")
        XCTAssertEqual(node.curRetries, 2)
        XCTAssertEqual(node.state, .succeeded)
    }
    
    /// 测试基础节点重试次数超过限制的情况
    /// 验证节点在重试次数超过最大限制后会抛出maxRetryExceeded错误
    func testBaseNodeMaxRetriesExceeded() async throws {
        final class MaxRetriesExceededNode: XYBaseNode<String> {
            override func runOnce() async throws -> String {
                throw XYError.other(NSError(domain: "Test", code: 0, userInfo: nil))
            }
        }
        
        let node = MaxRetriesExceededNode(maxRetries: 2)
        do {
            _ = try await node.execute()
            XCTFail("Expected maxRetryExceeded error to be thrown")
        } catch let error as XYError {
            XCTAssertEqual(error, XYError.maxRetryExceeded)
            XCTAssertEqual(node.curRetries, 2)
            XCTAssertEqual(node.state, .failed)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    /// 测试基础节点取消执行的情况
    /// 验证节点在执行过程中能够被正确取消
    func testBaseNodeCancel() async throws {
        final class CancelNode: XYBaseNode<String> {
            let executionTime: TimeInterval
            
            init(executionTime: TimeInterval = 1.0) {
                self.executionTime = executionTime
                super.init()
            }
            
            override func runOnce() async throws -> String {
                try await Task.sleep(seconds: executionTime)
                return "done"
            }
        }
        
        let node = CancelNode(executionTime: 1.0)
        let task = Task {
            try await node.execute()
        }
        
        // 等待一点时间让任务开始执行
        try await Task.sleep(seconds: 0.01)
        XCTAssertEqual(node.state, .executing)
        
        node.cancel()
        do {
            _ = try await task.value
            XCTFail("Expected cancelled error")
        } catch let error as XYError {
            XCTAssertEqual(error, XYError.cancelled)
            XCTAssertEqual(node.state, .cancelled)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}