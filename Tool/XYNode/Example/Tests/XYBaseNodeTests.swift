import XCTest
@testable import XYNode

class XYBaseNodeTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    /// 测试节点初始化
    func testNodeInitialization() {
        let node = XYBaseNode<String>(value: "root")
        XCTAssertNil(node.parent, "新节点的父节点应该为nil")
        XCTAssertTrue(node.children.isEmpty, "新节点的子节点数组应该为空")
        XCTAssertTrue(node.isRoot, "没有父节点的节点应该是根节点")
        XCTAssertTrue(node.isLeaf, "没有子节点的节点应该是叶节点")
        XCTAssertEqual(node.value, "root", "节点的值应该正确设置")
        XCTAssertNotNil(node.userInfo, "节点的用户信息字典应该存在")
        XCTAssertNil(node.identifier, "新节点的标识符应该为nil")
        XCTAssertTrue(node.tags.isEmpty, "新节点的标签集合应该为空")
        XCTAssertEqual(node.level, "", "新节点的层级应该为空字符串")
        XCTAssertEqual(node.levelDepth, 0, "新节点的层级深度应该为0")
    }
    
    // MARK: - Add Tests
    
    /// 测试添加子节点
    func testAppendChild() {
        let parentNode = XYBaseNode<Int>(value: 0)
        let childNode = XYBaseNode<Int>(value: 1)
        
        parentNode.append(child: childNode)
        
        XCTAssertEqual(parentNode.children.count, 1, "父节点应该有一个子节点")
        XCTAssertTrue(parentNode.children.contains { $0 === childNode }, "父节点应该包含指定的子节点")
        XCTAssertTrue(childNode.parent === parentNode, "子节点的父节点应该设置正确")
        XCTAssertEqual(childNode.level, "0", "子节点的层级应该正确设置")
    }
    
    /// 测试添加多个子节点
    func testAppendChildren() {
        let parentNode = XYBaseNode<String>(value: "root")
        let child1 = XYBaseNode<String>(value: "child1")
        let child2 = XYBaseNode<String>(value: "child2")
        let child3 = XYBaseNode<String>(value: "child3")
        
        parentNode.append(children: [child1, child2, child3])
        
        XCTAssertEqual(parentNode.children.count, 3, "父节点应该有三个子节点")
        XCTAssertTrue(parentNode.children.contains { $0 === child1 }, "父节点应该包含第一个子节点")
        XCTAssertTrue(parentNode.children.contains { $0 === child2 }, "父节点应该包含第二个子节点")
        XCTAssertTrue(parentNode.children.contains { $0 === child3 }, "父节点应该包含第三个子节点")
        XCTAssertTrue(child1.parent === parentNode, "第一个子节点的父节点应该设置正确")
        XCTAssertTrue(child2.parent === parentNode, "第二个子节点的父节点应该设置正确")
        XCTAssertTrue(child3.parent === parentNode, "第三个子节点的父节点应该设置正确")
        XCTAssertEqual(child1.level, "0", "第一个子节点的层级应该正确设置")
        XCTAssertEqual(child2.level, "1", "第二个子节点的层级应该正确设置")
        XCTAssertEqual(child3.level, "2", "第三个子节点的层级应该正确设置")
    }
    
    /// 测试在指定位置插入子节点
    func testInsertChildAtIndex() {
        let parentNode = XYBaseNode<String>(value: "root")
        let child1 = XYBaseNode<String>(value: "child1")
        let child2 = XYBaseNode<String>(value: "child2")
        let child3 = XYBaseNode<String>(value: "child3")
        
        parentNode.append(children: [child1, child3])
        parentNode.insert(child: child2, at: 1)
        
        XCTAssertEqual(parentNode.children.count, 3, "父节点应该有三个子节点")
        XCTAssertTrue(parentNode.children[0] === child1, "第一个位置应该是child1")
        XCTAssertTrue(parentNode.children[1] === child2, "第二个位置应该是child2")
        XCTAssertTrue(parentNode.children[2] === child3, "第三个位置应该是child3")
        XCTAssertEqual(child2.level, "1", "插入的子节点的层级应该正确设置")
    }
    
    // MARK: - Remove Tests
    
    /// 测试根据索引移除子节点
    func testRemoveChildAtIndex() {
        let parentNode = XYBaseNode<String>(value: "root")
        let child1 = XYBaseNode<String>(value: "child1")
        let child2 = XYBaseNode<String>(value: "child2")
        
        parentNode.append(children: [child1, child2])
        let removedNode = parentNode.removeChild(at: 0)
        
        XCTAssertTrue(removedNode === child1, "应该正确移除第一个子节点")
        XCTAssertNil(removedNode?.parent, "被移除节点的父节点应该为nil")
        XCTAssertEqual(parentNode.children.count, 1, "父节点应该只剩一个子节点")
        XCTAssertTrue(parentNode.children[0] === child2, "剩余的子节点应该是child2")
        XCTAssertEqual(child2.level, "0", "剩余子节点的层级应该更新")
    }
    
    /// 测试移除第一个子节点
    func testRemoveFirstChild() {
        let parentNode = XYBaseNode<String>(value: "root")
        let child1 = XYBaseNode<String>(value: "child1")
        let child2 = XYBaseNode<String>(value: "child2")
        
        parentNode.append(children: [child1, child2])
        let removedNode = parentNode.removeFirst()
        
        XCTAssertTrue(removedNode === child1, "应该正确移除第一个子节点")
        XCTAssertEqual(parentNode.children.count, 1, "父节点应该只剩一个子节点")
        XCTAssertTrue(parentNode.children[0] === child2, "剩余的子节点应该是child2")
    }
    
    /// 测试移除最后一个子节点
    func testRemoveLastChild() {
        let parentNode = XYBaseNode<String>(value: "root")
        let child1 = XYBaseNode<String>(value: "child1")
        let child2 = XYBaseNode<String>(value: "child2")
        
        parentNode.append(children: [child1, child2])
        let removedNode = parentNode.removeLast()
        
        XCTAssertTrue(removedNode === child2, "应该正确移除最后一个子节点")
        XCTAssertEqual(parentNode.children.count, 1, "父节点应该只剩一个子节点")
        XCTAssertTrue(parentNode.children[0] === child1, "剩余的子节点应该是child1")
    }
    
    /// 测试移除所有子节点
    func testRemoveAllChildren() {
        let parentNode = XYBaseNode<String>(value: "root")
        let child1 = XYBaseNode<String>(value: "child1")
        let child2 = XYBaseNode<String>(value: "child2")
        
        parentNode.append(children: [child1, child2])
        let removedNodes = parentNode.removeAll()
        
        XCTAssertEqual(removedNodes.count, 2, "应该移除两个节点")
        XCTAssertTrue(removedNodes.contains { $0 === child1 }, "应该包含第一个子节点")
        XCTAssertTrue(removedNodes.contains { $0 === child2 }, "应该包含第二个子节点")
        XCTAssertTrue(parentNode.children.isEmpty, "父节点的子节点数组应该为空")
        XCTAssertNil(child1.parent, "第一个子节点的父节点应该为nil")
        XCTAssertNil(child2.parent, "第二个子节点的父节点应该为nil")
    }
    
    // MARK: - Query Tests
    
    /// 测试根据索引查找子节点
    func testFindChildAtIndex() {
        let parentNode = XYBaseNode<String>(value: "root")
        let child1 = XYBaseNode<String>(value: "child1")
        let child2 = XYBaseNode<String>(value: "child2")
        
        parentNode.append(children: [child1, child2])
        let foundNode = parentNode.findChild(at: 1)
        
        XCTAssertTrue(foundNode === child2, "应该正确找到索引为1的子节点")
        XCTAssertNil(parentNode.findChild(at: 5), "查找无效索引应该返回nil")
        XCTAssertNil(parentNode.findChild(at: -1), "查找负数索引应该返回nil")
    }
    
    // MARK: - Tag Tests
    
    /// 测试标签功能
    func testTags() {
        let node = XYBaseNode<String>(value: "test")
        
        XCTAssertFalse(node.hasTag("tag1"), "节点初始时不应该包含任何标签")
        
        node.addTag("tag1")
        XCTAssertTrue(node.hasTag("tag1"), "节点应该包含添加的标签")
        
        node.removeTag("tag1")
        XCTAssertFalse(node.hasTag("tag1"), "节点不应该包含已移除的标签")
    }
    
    // MARK: - Path & Relationship Tests
    
    /// 测试获取从根到当前节点的路径
    func testGetPathToRoot() {
        let root = XYBaseNode<String>(value: "root")
        let child1 = XYBaseNode<String>(value: "child1")
        let child2 = XYBaseNode<String>(value: "child2")
        
        root.append(child: child1)
        child1.append(child: child2)
        
        let path = child2.getPathToRoot()
        XCTAssertEqual(path.count, 3, "路径应该包含3个节点")
        XCTAssertTrue(path[0] === root, "路径的第一个节点应该是根节点")
        XCTAssertTrue(path[1] === child1, "路径的第二个节点应该是child1")
        XCTAssertTrue(path[2] === child2, "路径的第三个节点应该是child2")
    }
    
    /// 测试判断祖先关系
    func testIsAncestor() {
        let root = XYBaseNode<String>(value: "root")
        let child1 = XYBaseNode<String>(value: "child1")
        let child2 = XYBaseNode<String>(value: "child2")
        
        root.append(child: child1)
        child1.append(child: child2)
        
        XCTAssertTrue(root.isAncestor(of: child2), "根节点应该是child2的祖先")
        XCTAssertTrue(root.isAncestor(of: child1), "根节点应该是child1的祖先")
        XCTAssertTrue(child1.isAncestor(of: child2), "child1应该是child2的祖先")
        XCTAssertFalse(child2.isAncestor(of: child1), "child2不应该是child1的祖先")
        XCTAssertFalse(child2.isAncestor(of: root), "child2不应该是根节点的祖先")
    }
    
    // MARK: - Find Tests
    
    /// 测试获取所有后代节点
    func testGetAllDescendants() {
        let root = XYBaseNode<String>(value: "root")
        let child1 = XYBaseNode<String>(value: "child1")
        let child2 = XYBaseNode<String>(value: "child2")
        let grandchild1 = XYBaseNode<String>(value: "grandchild1")
        let grandchild2 = XYBaseNode<String>(value: "grandchild2")
        
        root.append(children: [child1, child2])
        child1.append(children: [grandchild1, grandchild2])
        
        let descendants = root.getAllDescendants()
        XCTAssertEqual(descendants.count, 4, "根节点应该有4个后代节点")
        XCTAssertTrue(descendants.contains { $0 === child1 }, "后代节点应该包含child1")
        XCTAssertTrue(descendants.contains { $0 === child2 }, "后代节点应该包含child2")
        XCTAssertTrue(descendants.contains { $0 === grandchild1 }, "后代节点应该包含grandchild1")
        XCTAssertTrue(descendants.contains { $0 === grandchild2 }, "后代节点应该包含grandchild2")
    }
    
    /// 测试根据标识符查找后代节点
    func testFindDescendantWithIdentifier() {
        let root = XYBaseNode<String>(value: "root")
        let child1 = XYBaseNode<String>(value: "child1")
        let child2 = XYBaseNode<String>(value: "child2")
        let grandchild1 = XYBaseNode<String>(value: "grandchild1")
        
        child1.identifier = "child1"
        child2.identifier = "child2"
        grandchild1.identifier = "grandchild1"
        
        root.append(children: [child1, child2])
        child1.append(child: grandchild1)
        
        let foundNode = root.findDescendant(withIdentifier: "grandchild1")
        XCTAssertTrue(foundNode === grandchild1, "应该正确找到标识符为grandchild1的节点")
        
        XCTAssertNil(root.findDescendant(withIdentifier: "nonexistent"), "查找不存在的标识符应该返回nil")
    }
    
    // MARK: - Cache Tests
    
    /// 测试通过identifier查找节点的缓存功能
    func testFindNodeWithIdentifier() {
        let root = XYBaseNode<String>(value: "root")
        let child1 = XYBaseNode<String>(value: "child1")
        let child2 = XYBaseNode<String>(value: "child2")
        let grandchild1 = XYBaseNode<String>(value: "grandchild1")
        
        // 设置标识符
        child1.identifier = "child1"
        child2.identifier = "child2"
        grandchild1.identifier = "grandchild1"
        
        // 构建树结构
        root.append(children: [child1, child2])
        child1.append(child: grandchild1)
        
        // 测试通过缓存查找节点
        let foundNode1 = root.findNode(withIdentifier: "grandchild1")
        XCTAssertTrue(foundNode1 === grandchild1, "应该通过缓存正确找到标识符为grandchild1的节点")
        
        let foundNode2 = root.findNode(withIdentifier: "child1")
        XCTAssertTrue(foundNode2 === child1, "应该通过缓存正确找到标识符为child1的节点")
        
        let foundNode3 = root.findNode(withIdentifier: "child2")
        XCTAssertTrue(foundNode3 === child2, "应该通过缓存正确找到标识符为child2的节点")
        
        XCTAssertNil(root.findNode(withIdentifier: "nonexistent"), "查找不存在的标识符应该返回nil")
    }
    
    /// 测试通过tag查找节点数组的缓存功能
    func testFindNodesWithTag() {
        let root = XYBaseNode<String>(value: "root")
        let child1 = XYBaseNode<String>(value: "child1")
        let child2 = XYBaseNode<String>(value: "child2")
        let grandchild1 = XYBaseNode<String>(value: "grandchild1")
        let grandchild2 = XYBaseNode<String>(value: "grandchild2")
        
        // 添加标签
        child1.addTag("tagA")
        child2.addTag("tagA")
        child2.addTag("tagB")
        grandchild1.addTag("tagA")
        grandchild2.addTag("tagB")
        grandchild2.addTag("tagC")
        
        // 构建树结构
        root.append(children: [child1, child2])
        child1.append(child: grandchild1)
        child2.append(child: grandchild2)
        
        // 测试通过缓存查找具有特定标签的节点数组
        let nodesWithTagA = root.findNodes(withTag: "tagA")
        XCTAssertEqual(nodesWithTagA.count, 3, "应该找到3个具有tagA的节点")
        XCTAssertTrue(nodesWithTagA.contains { $0 === child1 }, "应该包含child1")
        XCTAssertTrue(nodesWithTagA.contains { $0 === child2 }, "应该包含child2")
        XCTAssertTrue(nodesWithTagA.contains { $0 === grandchild1 }, "应该包含grandchild1")
        
        let nodesWithTagB = root.findNodes(withTag: "tagB")
        XCTAssertEqual(nodesWithTagB.count, 2, "应该找到2个具有tagB的节点")
        XCTAssertTrue(nodesWithTagB.contains { $0 === child2 }, "应该包含child2")
        XCTAssertTrue(nodesWithTagB.contains { $0 === grandchild2 }, "应该包含grandchild2")
        
        let nodesWithTagC = root.findNodes(withTag: "tagC")
        XCTAssertEqual(nodesWithTagC.count, 1, "应该找到1个具有tagC的节点")
        XCTAssertTrue(nodesWithTagC.contains { $0 === grandchild2 }, "应该包含grandchild2")
        
        let nodesWithNonexistentTag = root.findNodes(withTag: "nonexistent")
        XCTAssertTrue(nodesWithNonexistentTag.isEmpty, "查找不存在的标签应该返回空数组")
    }
    
    /// 测试在添加子节点时更新缓存
    func testCacheUpdateOnAddingChildren() {
        let root = XYBaseNode<String>(value: "root")
        let child = XYBaseNode<String>(value: "child")
        let grandchild = XYBaseNode<String>(value: "grandchild")
        
        // 最初查找不存在的节点
        XCTAssertNil(root.findNode(withIdentifier: "child"), "添加前应该找不到child节点")
        XCTAssertTrue(root.findNodes(withTag: "tagA").isEmpty, "添加前应该找不到具有tagA的节点")
        
        // 设置标识符和标签
        child.identifier = "child"
        child.addTag("tagA")
        grandchild.identifier = "grandchild"
        grandchild.addTag("tagA")
        
        // 添加子节点
        root.append(child: child)
        child.append(child: grandchild)
        
        // 验证缓存已更新
        let foundChild = root.findNode(withIdentifier: "child")
        XCTAssertTrue(foundChild === child, "添加后应该能通过缓存找到child节点")
        
        let nodesWithTagA = root.findNodes(withTag: "tagA")
        XCTAssertEqual(nodesWithTagA.count, 2, "添加后应该能找到2个具有tagA的节点")
        XCTAssertTrue(nodesWithTagA.contains { $0 === child }, "应该包含child")
        XCTAssertTrue(nodesWithTagA.contains { $0 === grandchild }, "应该包含grandchild")
    }
    
    /// 测试在移除子节点时更新缓存
    func testCacheUpdateOnRemovingChildren() {
        let root = XYBaseNode<String>(value: "root")
        let child1 = XYBaseNode<String>(value: "child1")
        let child2 = XYBaseNode<String>(value: "child2")
        
        // 设置标识符和标签
        child1.identifier = "child1"
        child1.addTag("tagA")
        child2.identifier = "child2"
        child2.addTag("tagA")
        
        // 添加子节点
        root.append(children: [child1, child2])
        
        // 验证节点可通过缓存找到
        XCTAssertNotNil(root.findNode(withIdentifier: "child1"), "移除前应该能通过缓存找到child1节点")
        XCTAssertNotNil(root.findNode(withIdentifier: "child2"), "移除前应该能通过缓存找到child2节点")
        
        let nodesWithTagABefore = root.findNodes(withTag: "tagA")
        XCTAssertEqual(nodesWithTagABefore.count, 2, "移除前应该能找到2个具有tagA的节点")
        
        // 移除一个子节点
        root.removeChild(at: 0)
        
        // 验证缓存已更新
        XCTAssertNil(root.findNode(withIdentifier: "child1"), "移除后应该无法通过缓存找到child1节点")
        XCTAssertNotNil(root.findNode(withIdentifier: "child2"), "移除后应该仍能通过缓存找到child2节点")
        
        let nodesWithTagAAfter = root.findNodes(withTag: "tagA")
        XCTAssertEqual(nodesWithTagAAfter.count, 1, "移除后应该只能找到1个具有tagA的节点")
        XCTAssertTrue(nodesWithTagAAfter.contains { $0 === child2 }, "应该包含child2")
    }
    
    /// 测试在修改节点标识符时更新缓存
    func testCacheUpdateOnChangingIdentifier() {
        let root = XYBaseNode<String>(value: "root")
        let child = XYBaseNode<String>(value: "child")
        
        child.identifier = "oldIdentifier"
        root.append(child: child)
        
        // 验证可以通过旧标识符找到节点
        let foundWithOldId = root.findNode(withIdentifier: "oldIdentifier")
        XCTAssertTrue(foundWithOldId === child, "应该能通过旧标识符找到节点")
        
        // 更改标识符
        child.identifier = "newIdentifier"
        
        // 验证无法通过旧标识符找到节点，但可以通过新标识符找到
        XCTAssertNil(root.findNode(withIdentifier: "oldIdentifier"), "更改标识符后应该无法通过旧标识符找到节点")
        let foundWithNewId = root.findNode(withIdentifier: "newIdentifier")
        XCTAssertTrue(foundWithNewId === child, "应该能通过新标识符找到节点")
    }
    
    /// 测试在修改节点标签时更新缓存
    func testCacheUpdateOnChangingTags() {
        let root = XYBaseNode<String>(value: "root")
        let child = XYBaseNode<String>(value: "child")
        
        child.addTag("oldTag")
        root.append(child: child)
        
        // 验证可以通过旧标签找到节点
        var nodesWithOldTag = root.findNodes(withTag: "oldTag")
        XCTAssertEqual(nodesWithOldTag.count, 1, "应该能通过旧标签找到节点")
        XCTAssertTrue(nodesWithOldTag.contains { $0 === child }, "应该包含child节点")
        
        // 更改标签
        child.removeTag("oldTag")
        child.addTag("newTag")
        
        // 验证无法通过旧标签找到节点，但可以通过新标签找到
        nodesWithOldTag = root.findNodes(withTag: "oldTag")
        XCTAssertTrue(nodesWithOldTag.isEmpty, "更改标签后应该无法通过旧标签找到节点")
        
        let nodesWithNewTag = root.findNodes(withTag: "newTag")
        XCTAssertEqual(nodesWithNewTag.count, 1, "应该能通过新标签找到节点")
        XCTAssertTrue(nodesWithNewTag.contains { $0 === child }, "应该包含child节点")
    }
    
    // MARK: - Traverse Tests
    
    /// 测试深度优先遍历
    func testTraverseDFS() {
        let root = XYBaseNode<String>(value: "root")
        let child1 = XYBaseNode<String>(value: "child1")
        let child2 = XYBaseNode<String>(value: "child2")
        let grandchild1 = XYBaseNode<String>(value: "grandchild1")
        let grandchild2 = XYBaseNode<String>(value: "grandchild2")
        
        root.append(children: [child1, child2])
        child1.append(children: [grandchild1, grandchild2])
        
        var traversalOrder: [XYBaseNode<String>] = []
        root.traverseDFS { node in
            traversalOrder.append(node)
            return true
        }
        
        XCTAssertEqual(traversalOrder.count, 5, "应该遍历5个节点")
        XCTAssertTrue(traversalOrder[0] === root, "第一个遍历的节点应该是根节点")
        XCTAssertTrue(traversalOrder[1] === child1, "第二个遍历的节点应该是child1")
        XCTAssertTrue(traversalOrder[2] === grandchild1, "第三个遍历的节点应该是grandchild1")
        XCTAssertTrue(traversalOrder[3] === grandchild2, "第四个遍历的节点应该是grandchild2")
        XCTAssertTrue(traversalOrder[4] === child2, "第五个遍历的节点应该是child2")
    }
    
    /// 测试广度优先遍历
    func testTraverseBFS() {
        let root = XYBaseNode<String>(value: "root")
        let child1 = XYBaseNode<String>(value: "child1")
        let child2 = XYBaseNode<String>(value: "child2")
        let grandchild1 = XYBaseNode<String>(value: "grandchild1")
        let grandchild2 = XYBaseNode<String>(value: "grandchild2")
        
        root.append(children: [child1, child2])
        child1.append(children: [grandchild1, grandchild2])
        
        var traversalOrder: [XYBaseNode<String>] = []
        root.traverseBFS { node in
            traversalOrder.append(node)
            return true
        }
        
        XCTAssertEqual(traversalOrder.count, 5, "应该遍历5个节点")
        XCTAssertTrue(traversalOrder[0] === root, "第一个遍历的节点应该是根节点")
        XCTAssertTrue(traversalOrder[1] === child1, "第二个遍历的节点应该是child1")
        XCTAssertTrue(traversalOrder[2] === child2, "第三个遍历的节点应该是child2")
        XCTAssertTrue(traversalOrder[3] === grandchild1, "第四个遍历的节点应该是grandchild1")
        XCTAssertTrue(traversalOrder[4] === grandchild2, "第五个遍历的节点应该是grandchild2")
    }
}