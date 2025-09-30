//
//  XYTreeNode.swift
//  XYUtil
//
//  Created by hsf on 2025/9/30.
//

import Foundation

/// 树节点（用于可展开树，包含 UI 状态）
open class XYTreeNode<T>: XYExtendableNode<T> {
    // MARK: - Properties
    
    /// 层级字符串，例如: "0", "0.1", "2.3.0"
    public internal(set) var level: String = ""
    
    /// 层级深度（root 为 0）
    public var levelDepth: Int {
        guard !level.isEmpty else { return 0 }
        return level.components(separatedBy: ".").count
    }
    
    /// 是否展开（默认 true）
    public internal(set) var isExpanded: Bool = true
    
    /// 是否可展开（有子节点）
    public var isExpandable: Bool {
        !children.isEmpty
    }
    
    /// 是否可见（由可展开树控制）
    public internal(set) var isVisible: Bool = false
    
    /// 所属的可展开树（weak）
    public weak var expandableTree: XYExpandableTree<T>?
    
    /// 图标名称（用于UI显示）
    public var iconName: String?
    
    /// 节点颜色（用于UI显示）
    public var color: String?
    
    // MARK: - Lifecycle
    
    public override init(value: T?) {
        super.init(value: value)
    }
    
    // MARK: - Expand/Shrink
    
    public func expand() {
        expandableTree?.expand(node: self)
    }
    
    public func shrink() {
        expandableTree?.shrink(node: self)
    }
    
    public func expandOrShrink() {
        if isExpanded {
            shrink()
        } else {
            expand()
        }
    }
    
    // MARK: - Convenience Methods (类型安全)
    
    public func append(child: XYTreeNode<T>) {
        super.append(child: child)
    }
    
    public func append(children: [XYTreeNode<T>]) {
        super.append(children: children)
    }
    
    public func insert(child: XYTreeNode<T>, at index: Int) {
        super.insert(child: child, at: index)
    }
    
    public func insert(children: [XYTreeNode<T>], at index: Int) {
        super.insert(children: children, at: index)
    }
    
    @discardableResult
    public func removeChild(at index: Int) -> XYTreeNode<T>? {
        return super.removeChild(at: index) as? XYTreeNode<T>
    }
    
    public func findChild(at index: Int) -> XYTreeNode<T>? {
        return super.findChild(at: index) as? XYTreeNode<T>
    }
}
