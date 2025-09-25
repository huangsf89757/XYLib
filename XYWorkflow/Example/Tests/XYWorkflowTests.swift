import XCTest
import XYExtension
@testable import XYWorkflow

final class XYWorkflowTests: XCTestCase {
    
    final class TestNode: XYBaseNode<String> {
        let value: String
        let shouldFail: Bool
        
        init(value: String, shouldFail: Bool = false) {
            self.value = value
            self.shouldFail = shouldFail
            super.init()
        }
        
        override func runOnce() async throws -> String {
            if shouldFail {
                throw XYError.unknown(NSError(domain: "TestNode", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed node: \(value)"]))
            }
            return value
        }
    }
    
    /// 测试单节点工作流执行功能
    /// 验证仅包含一个节点的工作流能够正确执行并返回结果
    func testWorkflowSingleNode() async throws {
        let node = TestNode(value: "single")
        let workflow = XYWorkflow(root: node)
        
        let result = try await workflow.execute()
        XCTAssertEqual(result, "single")
        XCTAssertEqual(workflow.state, .succeeded)
    }
    
    /// 测试多节点工作流执行功能
    /// 验证包含多个链接节点的工作流能够按顺序正确执行
    func testWorkflowMultipleNodes() async throws {
        // 创建节点
        let node1 = TestNode(value: "first")
        let node2 = TestNode(value: "second")
        let node3 = TestNode(value: "third")
        
        // 链接节点
        node1.next = node2
        node2.prev = node1
        
        node2.next = node3
        node3.prev = node2
        
        // 创建工作流
        let workflow = XYWorkflow(root: node1)
        
        let result = try await workflow.execute()
        XCTAssertEqual(result, "third") // 最后一个节点的结果
        XCTAssertEqual(workflow.state, .succeeded)
    }
    
    /// 测试工作流执行失败的情况
    /// 验证当工作流中的某个节点执行失败时，整个工作流能够正确处理错误
    func testWorkflowWithFailure() async throws {
        // 创建节点
        let node1 = TestNode(value: "first")
        let node2 = TestNode(value: "second", shouldFail: true)
        let node3 = TestNode(value: "third")
        
        // 链接节点
        node1.next = node2
        node2.prev = node1
        
        node2.next = node3
        node3.prev = node2
        
        // 创建工作流
        let workflow = XYWorkflow(root: node1)
        
        do {
            _ = try await workflow.execute()
            XCTFail("Expected workflow to fail")
        } catch is XYError {
            XCTAssertEqual(workflow.state, .failed)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    /// 测试工作流取消功能
    /// 验证工作流在执行过程中能够被正确取消
    func testWorkflowCancel() async throws {
        // 创建耗时节点
        final class SlowNode: XYBaseNode<String> {
            let delay: TimeInterval
            
            init(delay: TimeInterval) {
                self.delay = delay
                super.init()
            }
            
            override func runOnce() async throws -> String {
                try await Task.sleep(seconds: delay)
                return "done"
            }
        }
        
        let node1 = SlowNode(delay: 1.0) // 1s
        let node2 = TestNode(value: "second")
        
        node1.next = node2
        node2.prev = node1
        
        let workflow = XYWorkflow(timeout: 10, root: node1)
        
        let task = Task {
            try await workflow.execute()
        }
        
        // 等待一点时间让工作流开始执行
        try await Task.sleep(seconds: 0.01)
        XCTAssertEqual(workflow.state, .executing)
        
        workflow.cancel()
        
        do {
            _ = try await task.value
            XCTFail("Expected cancelled error")
        } catch let error as XYError {
            XCTAssertEqual(error, .cancelled)
            XCTAssertEqual(workflow.state, .cancelled)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    /// 测试工作流超时功能
    /// 验证工作流在执行超时后能够正确处理
    func testWorkflowTimeout() async throws {
        final class SlowNode: XYBaseNode<String> {
            let delay: TimeInterval
            
            init(delay: TimeInterval) {
                self.delay = delay
                super.init()
            }
            
            override func runOnce() async throws -> String {
                try await Task.sleep(seconds: delay)
                return "done"
            }
        }
        
        let node = SlowNode(delay: 1.0) // 1s
        let workflow = XYWorkflow(timeout: 0.1, root: node) // 0.1s timeout
        
        do {
            _ = try await workflow.execute()
            XCTFail("Expected timeout error")
        } catch let error as XYError {
            XCTAssertEqual(error, .timeout) // 超时应该抛出timeout错误
            XCTAssertEqual(workflow.state, .failed)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}