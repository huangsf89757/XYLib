//import XCTest
//import XYExtension
//import XYWorkflow
//
//final class XYNodeTests: XCTestCase {
//    
//    final class TestNode: XYNode<String> {
//        let value: String
//        
//        init(value: String,
//             id: String = UUID().uuidString,
//             timeout: TimeInterval = 10,
//             next: TestNode? = nil,
//             prev: TestNode? = nil) {
//            self.value = value
//            super.init(id: id, timeout: timeout, next: next, prev: prev)
//        }
//        
//        override func run() async throws -> String {
//            return value
//        }
//    }
//    
//    /// 测试节点初始化功能
//    /// 验证节点创建时 next 和 prev 指针为 nil，ID 为有效的 UUID 格式
//    func testNodeInitialization() {
//        let node = TestNode(value: "test")
//        XCTAssertNil(node.next)
//        XCTAssertNil(node.prev)
//        XCTAssertEqual(node.id.count, 36) // UUID length
//    }
//    
//    /// 测试节点链接功能
//    /// 验证两个节点能够正确地建立前向和后向链接关系
//    func testNodeLinking() {
//        let node1 = TestNode(value: "node1")
//        let node2 = TestNode(value: "node2")
//        
//        // 链接节点
//        node1.next = node2
//        node2.prev = node1
//        
//        // 验证链接
//        XCTAssertNotNil(node1.next)
//        XCTAssertNotNil(node2.prev)
//        XCTAssertTrue(node1.next === node2)
//        XCTAssertTrue(node2.prev === node1)
//    }
//    
//    /// 测试节点断开链接功能
//    /// 验证三个节点组成的链表能够正确地断开部分链接
//    func testNodeUnlinking() {
//        let node1 = TestNode(value: "node1")
//        let node2 = TestNode(value: "node2")
//        let node3 = TestNode(value: "node3")
//        
//        // 建立链接: node1 <-> node2 <-> node3
//        node1.next = node2
//        node2.prev = node1
//        node2.next = node3
//        node3.prev = node2
//        
//        // 断开 node2 和 node3 的链接
//        node2.next = nil
//        node3.prev = nil
//        
//        // 验证链接状态
//        XCTAssertNotNil(node1.next)
//        XCTAssertNotNil(node2.prev)
//        XCTAssertTrue(node1.next === node2)
//        XCTAssertTrue(node2.prev === node1)
//        XCTAssertNil(node2.next)
//        XCTAssertNil(node3.prev)
//    }
//    
//    /// 测试节点属性设置功能
//    /// 验证节点的 ID 和超时时间属性能够被正确设置和获取
//    func testNodeProperties() {
//        let customId = "custom-id"
//        let timeout: TimeInterval = 30
//        let node = TestNode(value: "test", id: customId, timeout: timeout)
//        
//        XCTAssertEqual(node.id, customId)
//        XCTAssertEqual(node.timeout, timeout)
//    }
//}
