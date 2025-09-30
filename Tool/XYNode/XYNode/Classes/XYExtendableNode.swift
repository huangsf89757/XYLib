//
//  XYExtendableNode.swift
//  XYUtil
//
//  Created by hsf on 2025/9/30.
//

// IMPORT: System
import Foundation
// IMPORT: Basic
// IMPORT: Server
import XYLog
// IMPORT: Tool
// IMPORT: Business
// IMPORT: Third

// MARK: - ExpandStrategy
/// 展开/收起策略
public enum XYExpandStrategy {
    /// 保留子节点的展开状态（记忆模式）
    case preserve
    /// 重置子节点状态：收起时强制子节点收起，展开时子节点默认收起
    case reset
}

// MARK: - XYExtendableNode
/// 支持展开/收起及可见性计算的树节点（适用于 UI 场景）
open class XYExtendableNode<T>: XYBaseNode<T> {
    // MARK: var
    /// 是否处于展开状态（默认为 false，即收起）
    public var isExpanded: Bool = false
    
    // MARK: life cycle
    public override init(value: T?) {
        super.init(value: value)
        // isExpanded 默认 false，无需额外赋值
    }
}

// MARK: - Func
extension XYExtendableNode {
    /// 当前节点是否应在 UI 中可见（只读）
    /// - Note: 由根到当前节点路径上所有祖先的 `isExpanded` 状态决定
    public var isVisible: Bool {
        // 根节点始终可见
        guard let parent = self.parent else { return true }
        
        // 迭代方式：从当前节点向上遍历到根，检查每个祖先是否展开
        var current: XYBaseNode<T>? = parent
        while let node = current {
            guard let extendableNode = node as? XYExtendableNode<T> else {
                return false
            }
            if !extendableNode.isExpanded {
                return false
            }
            current = node.parent
        }
        return true
    }
    
    /// 是否可展开（有子节点才可展开）
    public var isExpandable: Bool {
        !children.isEmpty
    }
    
    /// 获取所有**可见的后代节点**（用于 UI 渲染）
    /// - Returns: 所有 `isVisible == true` 的后代节点（不包含自身）
    public func getVisibleDescendants() -> [XYExtendableNode<T>] {
        var visible: [XYExtendableNode<T>] = []
        for child in children {
            if let extendableChild = child as? XYExtendableNode<T> {
                if extendableChild.isVisible {
                    visible.append(extendableChild)
                    visible.append(contentsOf: extendableChild.getVisibleDescendants())
                }
            }
        }
        return visible
    }
}

// MARK: - Expand / Collapse
extension XYExtendableNode {
    /// 展开当前节点
    /// - Parameters:
    ///   - strategy: 展开策略（默认 `.preserve`）
    ///   - recursively: 是否递归应用策略到所有后代（仅对 `.reset` 有意义）
    public func expand(strategy: XYExpandStrategy = .preserve,
                       recursively: Bool = false) {
        isExpanded = true
        if case .reset = strategy {
            // 重置模式：展开时子节点默认收起
            for child in children {
                if let extendableChild = child as? XYExtendableNode<T> {
                    extendableChild.isExpanded = false
                    if recursively {
                        extendableChild.collapse(strategy: .reset, recursively: true)
                    }
                }
            }
        }
        // .preserve 模式：不做任何子节点状态变更，保留原有状态
    }
    
    /// 收起当前节点
    /// - Parameters:
    ///   - strategy: 收起策略（默认 `.preserve`）
    ///   - recursively: 是否递归应用策略到所有后代
    public func collapse(strategy: XYExpandStrategy = .preserve,
                         recursively: Bool = false) {
        isExpanded = false
        if case .reset = strategy {
            // 重置模式：收起时强制所有子节点收起
            for child in children {
                if let extendableChild = child as? XYExtendableNode<T> {
                    extendableChild.isExpanded = false
                    if recursively {
                        extendableChild.collapse(strategy: .reset, recursively: true)
                    }
                }
            }
        }
        // .preserve 模式：仅收起当前节点，子节点状态保留（但因父节点收起而不可见）
    }
    
    /// 切换展开/收起状态
    /// - Parameters:
    ///   - strategy: 使用的策略
    ///   - recursively: 是否递归
    /// - Returns: 新的展开状态
    @discardableResult
    public func toggleExpand(strategy: XYExpandStrategy = .preserve,
                             recursively: Bool = false) -> Bool {
        if isExpanded {
            collapse(strategy: strategy, recursively: recursively)
        } else {
            expand(strategy: strategy, recursively: recursively)
        }
        return isExpanded
    }
}
