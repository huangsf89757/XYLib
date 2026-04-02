import XCTest
@testable import XYNode

class XYExtendableNodeTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    /// 测试可扩展节点初始化
    func testExtendableNodeInitialization() {
        let node = XYExtendableNode<String>(value: "root")
        XCTAssertFalse(node.isExpanded, "新节点默认应该处于收起状态")
        XCTAssertFalse(node.isExpandable, "没有子节点的节点不应该可展开")
    }
    
    // MARK: - Visibility Tests
    
    /// 测试节点可见性
    func testNodeVisibility() {
        let root = XYExtendableNode<String>(value: "root")
        let child = XYExtendableNode<String>(value: "child")
        let grandchild = XYExtendableNode<String>(value: "grandchild")
        
        root.append(child: child)
        child.append(child: grandchild)
        
        // 根节点始终可见
        XCTAssertTrue(root.isVisible, "根节点应该始终可见")
        
        // 子节点默认不可见（因为父节点默认收起）
        XCTAssertFalse(child.isVisible, "收起状态的父节点的子节点应该不可见")
        XCTAssertFalse(grandchild.isVisible, "收起状态的祖先节点的后代节点应该不可见")
        
        // 展开父节点后，子节点应该可见
        root.expand()
        XCTAssertTrue(child.isVisible, "展开状态的父节点的子节点应该可见")
        XCTAssertFalse(grandchild.isVisible, "收起状态的父节点的子节点应该不可见")
        
        // 展开子节点后，孙节点应该可见
        child.expand()
        XCTAssertTrue(grandchild.isVisible, "展开状态的父节点的子节点应该可见")
    }
    
    // MARK: - Expandable Tests
    
    /// 测试节点是否可展开
    func testNodeExpandable() {
        let node = XYExtendableNode<String>(value: "node")
        XCTAssertFalse(node.isExpandable, "没有子节点的节点不应该可展开")
        
        let child = XYExtendableNode<String>(value: "child")
        node.append(child: child)
        XCTAssertTrue(node.isExpandable, "有子节点的节点应该可展开")
    }
    
    // MARK: - Expand/Collapse Tests
    
    /// 测试展开节点（preserve策略）
    func testExpandWithPreserveStrategy() {
        let parent = XYExtendableNode<String>(value: "parent")
        let child1 = XYExtendableNode<String>(value: "child1")
        let child2 = XYExtendableNode<String>(value: "child2")
        
        parent.append(children: [child1, child2])
        
        // 先展开子节点
        child1.expand()
        XCTAssertTrue(child1.isExpanded, "子节点应该处于展开状态")
        
        // 展开父节点（使用preserve策略）
        parent.expand(strategy: .preserve)
        XCTAssertTrue(parent.isExpanded, "父节点应该处于展开状态")
        XCTAssertTrue(child1.isExpanded, "使用preserve策略时，子节点应该保持原有状态")
    }
    
    /// 测试展开节点（reset策略）
    func testExpandWithResetStrategy() {
        let parent = XYExtendableNode<String>(value: "parent")
        let child1 = XYExtendableNode<String>(value: "child1")
        let child2 = XYExtendableNode<String>(value: "child2")
        
        parent.append(children: [child1, child2])
        
        // 先展开子节点
        child1.expand()
        XCTAssertTrue(child1.isExpanded, "子节点应该处于展开状态")
        
        // 展开父节点（使用reset策略）
        parent.expand(strategy: .reset)
        XCTAssertTrue(parent.isExpanded, "父节点应该处于展开状态")
        XCTAssertFalse(child1.isExpanded, "使用reset策略时，子节点应该被收起")
        XCTAssertFalse(child2.isExpanded, "使用reset策略时，子节点应该被收起")
    }
    
    /// 测试收起节点（preserve策略）
    func testCollapseWithPreserveStrategy() {
        let parent = XYExtendableNode<String>(value: "parent")
        let child = XYExtendableNode<String>(value: "child")
        
        parent.append(child: child)
        
        // 展开所有节点
        parent.expand()
        child.expand()
        XCTAssertTrue(parent.isExpanded, "父节点应该处于展开状态")
        XCTAssertTrue(child.isExpanded, "子节点应该处于展开状态")
        
        // 收起父节点（使用preserve策略）
        parent.collapse(strategy: .preserve)
        XCTAssertFalse(parent.isExpanded, "父节点应该处于收起状态")
        XCTAssertTrue(child.isExpanded, "使用preserve策略时，子节点应该保持原有状态")
    }
    
    /// 测试收起节点（reset策略）
    func testCollapseWithResetStrategy() {
        let parent = XYExtendableNode<String>(value: "parent")
        let child = XYExtendableNode<String>(value: "child")
        
        parent.append(child: child)
        
        // 展开所有节点
        parent.expand()
        child.expand()
        XCTAssertTrue(parent.isExpanded, "父节点应该处于展开状态")
        XCTAssertTrue(child.isExpanded, "子节点应该处于展开状态")
        
        // 收起父节点（使用reset策略）
        parent.collapse(strategy: .reset)
        XCTAssertFalse(parent.isExpanded, "父节点应该处于收起状态")
        XCTAssertFalse(child.isExpanded, "使用reset策略时，子节点应该被收起")
    }
    
    /// 测试切换展开状态
    func testToggleExpand() {
        let node = XYExtendableNode<String>(value: "node")
        let child = XYExtendableNode<String>(value: "child")
        node.append(child: child)
        
        // 初始状态为收起
        XCTAssertFalse(node.isExpanded, "节点初始应该处于收起状态")
        
        // 切换状态
        let newState = node.toggleExpand()
        XCTAssertTrue(newState, "切换后应该处于展开状态")
        XCTAssertTrue(node.isExpanded, "节点应该处于展开状态")
        
        // 再次切换
        let newState2 = node.toggleExpand()
        XCTAssertFalse(newState2, "再次切换后应该处于收起状态")
        XCTAssertFalse(node.isExpanded, "节点应该处于收起状态")
    }
    
    // MARK: - Visible Descendants Tests
    
    /// 测试获取可见后代节点
    func testGetVisibleDescendants() {
        let root = XYExtendableNode<String>(value: "root")
        let child1 = XYExtendableNode<String>(value: "child1")
        let child2 = XYExtendableNode<String>(value: "child2")
        let grandchild1 = XYExtendableNode<String>(value: "grandchild1")
        let grandchild2 = XYExtendableNode<String>(value: "grandchild2")
        
        root.append(children: [child1, child2])
        child1.append(children: [grandchild1, grandchild2])
        
        // 初始状态：只有根节点的直接子节点可见（但因为根节点未展开，所以实际上都不可见）
        root.expand()
        var visibleDescendants = root.getVisibleDescendants()
        XCTAssertEqual(visibleDescendants.count, 2, "根节点展开后应该有两个可见的直接子节点")
        XCTAssertTrue(visibleDescendants.contains { $0 === child1 }, "可见后代应该包含child1")
        XCTAssertTrue(visibleDescendants.contains { $0 === child2 }, "可见后代应该包含child2")
        
        // 展开child1后，应该能看到grandchild1和grandchild2
        child1.expand()
        visibleDescendants = root.getVisibleDescendants()
        XCTAssertEqual(visibleDescendants.count, 4, "应该有四个可见的后代节点")
        XCTAssertTrue(visibleDescendants.contains { $0 === child1 }, "可见后代应该包含child1")
        XCTAssertTrue(visibleDescendants.contains { $0 === child2 }, "可见后代应该包含child2")
        XCTAssertTrue(visibleDescendants.contains { $0 === grandchild1 }, "可见后代应该包含grandchild1")
        XCTAssertTrue(visibleDescendants.contains { $0 === grandchild2 }, "可见后代应该包含grandchild2")
    }
    
    // MARK: - Recursive Expand/Collapse Tests
    
    /// 测试递归展开
    func testRecursiveExpand() {
        let root = XYExtendableNode<String>(value: "root")
        let child = XYExtendableNode<String>(value: "child")
        let grandchild = XYExtendableNode<String>(value: "grandchild")
        
        root.append(child: child)
        child.append(child: grandchild)
        
        root.expand(strategy: .reset, recursively: true)
        
        XCTAssertTrue(root.isExpanded, "根节点应该处于展开状态")
        XCTAssertFalse(child.isExpanded, "使用reset策略时，子节点应该被收起")
        XCTAssertFalse(grandchild.isExpanded, "使用reset策略时，孙节点应该被收起")
    }
    
    /// 测试递归收起
    func testRecursiveCollapse() {
        let root = XYExtendableNode<String>(value: "root")
        let child = XYExtendableNode<String>(value: "child")
        let grandchild = XYExtendableNode<String>(value: "grandchild")
        
        root.append(child: child)
        child.append(child: grandchild)
        
        // 先全部展开
        root.expand()
        child.expand()
        grandchild.expand()
        
        XCTAssertTrue(root.isExpanded, "根节点应该处于展开状态")
        XCTAssertTrue(child.isExpanded, "子节点应该处于展开状态")
        XCTAssertTrue(grandchild.isExpanded, "孙节点应该处于展开状态")
        
        // 递归收起
        root.collapse(strategy: .reset, recursively: true)
        
        XCTAssertFalse(root.isExpanded, "根节点应该处于收起状态")
        XCTAssertFalse(child.isExpanded, "子节点应该处于收起状态")
        XCTAssertFalse(grandchild.isExpanded, "孙节点应该处于收起状态")
    }
}