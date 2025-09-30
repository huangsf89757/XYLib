//
//  XYBaseNode.swift
//  XYUtil
//
//  Created by hsf on 2025/9/30.
//

import Foundation

/// 基础树节点（最简实现）
open class XYBaseNode<T> {
    // MARK: - Properties
    
    /// 节点值
    public internal(set) var value: T?
    
    /// 父节点（weak 避免循环引用）
    public weak var parent: XYBaseNode<T>?
    
    /// 子节点（强引用）
    public internal(set) var children: [XYBaseNode<T>] = []
    
    // MARK: - Lifecycle
    
    public init(value: T?) {
        self.value = value
    }
    
    deinit {
        #if DEBUG
        print("XYBaseNode deinit: \(value ?? "nil")")
        #endif
    }
}

// MARK: - CRUD Operations (通用)
extension XYBaseNode {
    // MARK: Add
    
    public func append(child: XYBaseNode<T>) {
        append(children: [child])
    }
    
    public func append(children: [XYBaseNode<T>]) {
        insert(children: children, at: self.children.count)
    }
    
    public func insert(child: XYBaseNode<T>, at index: Int) {
        insert(children: [child], at: index)
    }
    
    public func insert(children: [XYBaseNode<T>], at index: Int) {
        guard index >= 0 && index <= self.children.count else { return }
        for child in children {
            child.parent = self
        }
        self.children.insert(contentsOf: children, at: index)
    }
    
    // MARK: Remove
    
    @discardableResult
    public func removeChild(at index: Int) -> XYBaseNode<T>? {
        guard index >= 0 && index < children.count else { return nil }
        return children.remove(at: index)
    }
    
    @discardableResult
    public func removeFirst() -> XYBaseNode<T>? {
        return children.isEmpty ? nil : removeChild(at: 0)
    }
    
    @discardableResult
    public func removeLast() -> XYBaseNode<T>? {
        return children.isEmpty ? nil : removeChild(at: children.count - 1)
    }
    
    @discardableResult
    public func removeAll() -> [XYBaseNode<T>] {
        let removed = children
        children = []
        return removed
    }
    
    @discardableResult
    public func removeChildren(in range: Range<Int>) -> [XYBaseNode<T>] {
        guard !children.isEmpty,
              range.lowerBound >= 0,
              range.upperBound <= children.count else { return [] }
        let removed = Array(children[range])
        children.removeSubrange(range)
        return removed
    }
    
    // MARK: Update
    
    @discardableResult
    public func replaceChild(at index: Int, with child: XYBaseNode<T>) -> XYBaseNode<T>? {
        guard index >= 0 && index < children.count else { return nil }
        let oldChild = children[index]
        children[index] = child
        child.parent = self
        return oldChild
    }
    
    // MARK: Query
    
    public func findChild(at index: Int) -> XYBaseNode<T>? {
        guard index >= 0 && index < children.count else { return nil }
        return children[index]
    }
    
    public func findChildren(in range: Range<Int>) -> [XYBaseNode<T>] {
        guard !children.isEmpty,
              range.lowerBound >= 0,
              range.upperBound <= children.count else { return [] }
        return Array(children[range])
    }
}
