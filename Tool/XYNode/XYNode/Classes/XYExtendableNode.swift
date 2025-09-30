//
//  XYExtendableNode.swift
//  XYUtil
//
//  Created by hsf on 2025/9/30.
//

import Foundation

/// 可扩展节点基类（支持自定义属性和协议）
open class XYExtendableNode<T>: XYBaseNode<T> {
    // MARK: - Properties
    
    /// 自定义用户数据（可用于存储额外信息）
    public var userInfo: [String: Any] = [:]
    
    /// 节点标识符（可选，用于快速查找）
    public var identifier: String?
    
    /// 是否启用（可用于过滤）
    public var isEnabled: Bool = true
    
    /// 自定义标签（可用于分类）
    public var tags: Set<String> = []
    
    // MARK: - Lifecycle
    
    public override init(value: T?) {
        super.init(value: value)
    }
    
    // MARK: - Convenience Methods
    
    /// 检查是否包含指定标签
    public func hasTag(_ tag: String) -> Bool {
        return tags.contains(tag)
    }
    
    /// 添加标签
    public func addTag(_ tag: String) {
        tags.insert(tag)
    }
    
    /// 移除标签
    public func removeTag(_ tag: String) {
        tags.remove(tag)
    }
    
    /// 获取所有后代节点（递归）
    public func getAllDescendants() -> [XYExtendableNode<T>] {
        var descendants: [XYExtendableNode<T>] = []
        for child in children {
            if let extendableChild = child as? XYExtendableNode<T> {
                descendants.append(extendableChild)
                descendants.append(contentsOf: extendableChild.getAllDescendants())
            }
        }
        return descendants
    }
    
    /// 查找具有指定标识符的后代节点
    public func findDescendant(withIdentifier identifier: String) -> XYExtendableNode<T>? {
        for child in children {
            if let extendableChild = child as? XYExtendableNode<T> {
                if extendableChild.identifier == identifier {
                    return extendableChild
                }
                if let found = extendableChild.findDescendant(withIdentifier: identifier) {
                    return found
                }
            }
        }
        return nil
    }
}
