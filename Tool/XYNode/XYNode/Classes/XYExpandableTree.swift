//
//  XYExpandableTree.swift
//  XYUtil
//
//  Created by hsf on 2025/9/30.
//

import Foundation

/// 可展开树（支持展开/收起、可见节点管理）
open class XYExpandableTree<T>: XYBaseTree<T> {
    // MARK: - Properties
    
    /// 所有当前可见的节点（不包含 root）
    public private(set) var visibleNodes: [XYTreeNode<T>] = []
    
    /// 刷新完成回调
    public var reloadCompleteBlock: (() -> Void)?
    
    // MARK: - Lifecycle
    
    public override init() {
        super.init()
        // 确保 root 是 XYTreeNode
        if !(root is XYTreeNode<T>) {
            let newRoot = XYTreeNode<T>(value: nil)
            newRoot.expandableTree = self
            newRoot.level = ""
            self.root = newRoot
        } else if let treeNode = root as? XYTreeNode<T> {
            treeNode.expandableTree = self
            treeNode.level = ""
        }
    }
    
    // MARK: - Expand / Shrink
    
    public func expand(node: XYTreeNode<T>) {
        guard node.isExpandable, node.expandableTree === self else { return }
        #if DEBUG
        print("[XYExpandableTree] 展开节点 level: \(node.level)")
        #endif
        node.isExpanded = true
        reload()
    }
    
    public func shrink(node: XYTreeNode<T>) {
        guard node.isExpandable, node.expandableTree === self else { return }
        #if DEBUG
        print("[XYExpandableTree] 收缩节点 level: \(node.level)")
        #endif
        node.isExpanded = false
        reload()
    }
    
    // MARK: - Reload & Visibility Management
    
    /// 重新计算 level 和 visibleNodes
    public func reload() {
        // 第一步：DFS 设置所有节点的 level
        func updateLevels(for node: XYTreeNode<T>, parentLevel: String, index: Int) {
            node.expandableTree = self
            if parentLevel.isEmpty {
                node.level = "\(index)"
            } else {
                node.level = "\(parentLevel).\(index)"
            }
            
            for (idx, child) in node.children.enumerated() {
                if let childNode = child as? XYTreeNode<T> {
                    updateLevels(for: childNode, parentLevel: node.level, index: idx)
                }
            }
        }
        
        // 处理 root 的子节点
        for (index, child) in root.children.enumerated() {
            if let childNode = child as? XYTreeNode<T> {
                updateLevels(for: childNode, parentLevel: "", index: index)
            }
        }
        
        // 第二步：计算 visibleNodes
        var visible: [XYTreeNode<T>] = []
        var stack: [XYTreeNode<T>] = []
        
        // 从 root 的子节点开始
        for child in root.children.reversed() {
            if let treeNode = child as? XYTreeNode<T> {
                stack.append(treeNode)
            }
        }
        
        while !stack.isEmpty {
            let node = stack.removeLast()
            node.isVisible = true
            visible.append(node)
            
            if node.isExpanded {
                for child in node.children.reversed() {
                    if let treeNode = child as? XYTreeNode<T> {
                        stack.append(treeNode)
                    }
                }
            }
        }
        
        self.visibleNodes = visible
        self.reloadCompleteBlock?()
    }
    
    // MARK: - Override Base Methods
    
    public override func clear() {
        super.clear()
        visibleNodes = []
        reloadCompleteBlock?()
    }
    
    public override func addRootChild(_ node: XYBaseNode<T>) {
        super.addRootChild(node)
        if let treeNode = node as? XYTreeNode<T> {
            treeNode.expandableTree = self
        }
        reload()
    }
    
    public override func addRootChildren(_ nodes: [XYBaseNode<T>]) {
        super.addRootChildren(nodes)
        for node in nodes {
            if let treeNode = node as? XYTreeNode<T> {
                treeNode.expandableTree = self
            }
        }
        reload()
    }
    
    /// 查找可见节点中具有指定标识符的节点
    public func findVisibleNode(withIdentifier identifier: String) -> XYTreeNode<T>? {
        return visibleNodes.first { $0.identifier == identifier }
    }
}
