//
//  XYBaseTree.swift
//  XYUtil
//
//  Created by hsf on 2025/9/30.
//

import Foundation

/// 基础树（通用树结构管理）
open class XYBaseTree<T> {
    // MARK: - Properties
    
    /// 根节点
    public private(set) var root: XYBaseNode<T>
    
    // MARK: - Lifecycle
    
    public init() {
        self.root = XYBaseNode(value: nil)
    }
    
    deinit {
        #if DEBUG
        print("XYBaseTree deinit")
        #endif
    }
    
    // MARK: - Tree Operations
    
    /// 清空树
    public func clear() {
        _ = root.removeAll()
    }
    
    /// 添加根级子节点
    public func addRootChild(_ node: XYBaseNode<T>) {
        root.append(child: node)
    }
    
    /// 批量添加根级子节点
    public func addRootChildren(_ nodes: [XYBaseNode<T>]) {
        root.append(children: nodes)
    }
}

// MARK: - Traversal
extension XYBaseTree {
    /// 深度优先遍历（DFS）
    public func traverseDFS(from node: XYBaseNode<T>, _ closure: (XYBaseNode<T>) -> Bool) {
        var stack: [XYBaseNode<T>] = [node]
        while !stack.isEmpty {
            let current = stack.removeLast()
            let shouldContinue = closure(current)
            if !shouldContinue { break }
            for child in current.children.reversed() {
                stack.append(child)
            }
        }
    }
    
    /// 广度优先遍历（BFS）
    public func traverseBFS(from node: XYBaseNode<T>, _ closure: (XYBaseNode<T>) -> Bool) {
        var queue: [XYBaseNode<T>] = [node]
        while !queue.isEmpty {
            let current = queue.removeFirst()
            let shouldContinue = closure(current)
            if !shouldContinue { break }
            queue.append(contentsOf: current.children)
        }
    }
    
    /// 遍历整棵树（跳过 root）
    public func traverseAll(_ closure: (XYBaseNode<T>) -> Bool) {
        for child in root.children {
            if !closure(child) { break }
            traverseDFS(from: child, closure)
        }
    }
    
    /// 查找具有指定标识符的节点（仅在可扩展节点中查找）
    public func findNode(withIdentifier identifier: String) -> XYExtendableNode<T>? {
        var found: XYExtendableNode<T>?
        traverseAll { node in
            if let extendableNode = node as? XYExtendableNode<T>,
               extendableNode.identifier == identifier {
                found = extendableNode
                return false // 停止遍历
            }
            return true
        }
        return found
    }
}
