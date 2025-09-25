import Foundation
import XYWorkflow

// 示例：创建一个简单的工作流
class ExampleNode: XYBaseNode<String> {
    private let message: String
    
    init(message: String) {
        self.message = message
        super.init()
    }
    
    override func runOnce() async throws -> String {
        // 模拟一些异步工作
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1秒
        print("执行节点: \(message)")
        return "完成: \(message)"
    }
}

// 使用示例
func runWorkflowExample() async {
    // 创建节点
    let node1 = ExampleNode(message: "第一步")
    let node2 = ExampleNode(message: "第二步")
    let node3 = ExampleNode(message: "第三步")
    
    // 链接节点
    node1.next = node2
    node2.prev = node1
    
    node2.next = node3
    node3.prev = node2
    
    // 创建工作流
    let workflow = XYWorkflow(root: node1)
    
    // 执行工作流
    do {
        let result = try await workflow.execute()
        print("工作流执行完成，最终结果: \(result ?? "无结果")")
    } catch {
        print("工作流执行失败: \(error)")
    }
}