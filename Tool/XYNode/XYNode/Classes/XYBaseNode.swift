//
//  XYBaseNode.swift
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
import XYUtil
// IMPORT: Business
// IMPORT: Third

// MARK: - XYBaseNode
/// 基础树节点（最简实现）
open class XYBaseNode<T> {
    // MARK: var
    /// 节点值
    public internal(set) var value: T?
    
    /// 自定义用户数据（可用于存储额外信息）
    public var userInfo: [String: Any] = [:]
    
    /// 节点标识符（可选，用于快速查找）
    public var identifier: XYIdentifier? {
        didSet {
            // 当identifier改变时，更新缓存
            if let oldIdentifier = oldValue {
                removeFromIdentifierCache(node: self, identifier: oldIdentifier)
            }
            if let newIdentifier = identifier {
                addToIdentifierCache(node: self, identifier: newIdentifier)
            }
        }
    }
    
    /// 自定义标签（可用于分类）
    public var tags: Set<XYTag> = [] {
        didSet {
            // 当tags改变时，更新标签缓存
            let removedTags = oldValue.subtracting(tags)
            let addedTags = tags.subtracting(oldValue)
            
            for tag in removedTags {
                removeFromTagCache(node: self, tag: tag)
            }
            
            for tag in addedTags {
                addToTagCache(node: self, tag: tag)
            }
        }
    }
    
    /// 父节点
    public weak var parent: XYBaseNode<T>? {
        didSet {
            // 父节点变化时，可能需要更新缓存
            if let root = getRoot() {
                root.invalidateCache()
            }
        }
    }
    
    /// 子节点
    public internal(set) var children: [XYBaseNode<T>] = []
    
    /// 是否为根节点（无父节点）
    public var isRoot: Bool { parent == nil }
    
    /// 是否为叶子节点（无子节点）
    public var isLeaf: Bool { children.isEmpty }
    
    /// 层级字符串，例如: "0", "0.1", "2.3.0"
    public internal(set) var level: String = ""
    
    /// 层级深度（root 为 0）
    /// - Note: 根节点 level 为空字符串，depth 为 0；其直接子节点 level="0"，depth=1
    public var levelDepth: Int {
        guard !level.isEmpty else { return 0 }
        return level.components(separatedBy: ".").count
    }
    
    // MARK: Cache
    /// 缓存：根据identifier快速查找节点
    private var identifierCache: [XYIdentifier: XYBaseNode<T>] = [:]
    
    /// 缓存：根据tag快速查找节点数组
    private var tagCache: [XYTag: [XYBaseNode<T>]] = [:]
    
    /// 标记缓存是否有效
    private var isCacheValid = false
    
    // MARK: life cycle
    public init(value: T?) {
        self.value = value
    }
}

// MARK: - 增删改查
extension XYBaseNode {
    // MARK: Add
    /// 添加一个子节点到节点末尾
    /// - Parameter child: 要添加的子节点
    public func append(child: XYBaseNode<T>) {
        append(children: [child])
    }
    
    /// 添加多个子节点到节点末尾
    /// - Parameter children: 要添加的子节点数组
    public func append(children: [XYBaseNode<T>]) {
        insert(children: children, at: self.children.count)
    }
    
    /// 在指定位置插入一个子节点
    /// - Parameters:
    ///   - child: 要插入的子节点
    ///   - index: 插入位置的索引
    public func insert(child: XYBaseNode<T>, at index: Int) {
        insert(children: [child], at: index)
    }
    
    /// 在指定位置插入多个子节点
    /// - Parameters:
    ///   - children: 要插入的子节点数组
    ///   - index: 插入位置的索引
    public func insert(children: [XYBaseNode<T>], at index: Int) {
        guard index >= 0 && index <= self.children.count else { return }
        for child in children {
            child.parent = self
        }
        self.children.insert(contentsOf: children, at: index)
        
        // 自动更新新插入节点及其子树的 level
        updateLevelForNewChildren(startIndex: index, count: children.count)
        
        // 更新缓存
        for child in children {
            buildCacheForSubtree(node: child)
        }
        invalidateCache()
    }
    
    // MARK: Remove
    /// 根据索引移除子节点，并断开父子关系
    /// - Parameter index: 要移除的子节点索引
    /// - Returns: 被移除的节点，如果索引无效则返回nil
    @discardableResult
    public func removeChild(at index: Int) -> XYBaseNode<T>? {
        guard index >= 0 && index < children.count else { return nil }
        let removed = children.remove(at: index)
        removed.parent = nil
        // 移除后需刷新后续兄弟节点及其子树的 level
        for (i, child) in children.suffix(from: index).enumerated() {
            child.level = level.isEmpty ? String(index + i) : "\(level).\(index + i)"
            child.refreshLevel()
        }
        
        // 更新缓存
        removeFromCache(node: removed)
        invalidateCache()
        return removed
    }
    
    /// 移除第一个子节点，并断开父子关系
    /// - Returns: 被移除的节点，如果无子节点则返回nil
    @discardableResult
    public func removeFirst() -> XYBaseNode<T>? {
        return children.isEmpty ? nil : removeChild(at: 0)
    }
    
    /// 移除最后一个子节点，并断开父子关系
    /// - Returns: 被移除的节点，如果无子节点则返回nil
    @discardableResult
    public func removeLast() -> XYBaseNode<T>? {
        return children.isEmpty ? nil : removeChild(at: children.count - 1)
    }
    
    /// 移除所有子节点，并断开所有父子关系
    /// - Returns: 被移除的所有节点数组
    @discardableResult
    public func removeAll() -> [XYBaseNode<T>] {
        let removed = children
        children = []
        for node in removed {
            node.parent = nil
        }
        
        // 更新缓存
        for node in removed {
            removeFromCache(node: node)
        }
        invalidateCache()
        return removed
    }
    
    /// 移除指定范围内的子节点，并断开父子关系
    /// - Parameter range: 要移除的节点范围
    /// - Returns: 被移除的节点数组
    @discardableResult
    public func removeChildren(in range: Range<Int>) -> [XYBaseNode<T>] {
        guard !children.isEmpty,
              range.lowerBound >= 0,
              range.upperBound <= children.count else { return [] }
        let removed = Array(children[range])
        children.removeSubrange(range)
        for node in removed {
            node.parent = nil
        }
        // 刷新 range.lowerBound 之后的所有兄弟节点
        for (i, child) in children.suffix(from: range.lowerBound).enumerated() {
            let newIndex = range.lowerBound + i
            child.level = level.isEmpty ? String(newIndex) : "\(level).\(newIndex)"
            child.refreshLevel()
        }
        
        // 更新缓存
        for node in removed {
            removeFromCache(node: node)
        }
        invalidateCache()
        return removed
    }
    
    // MARK: Update
    /// 替换指定位置的子节点，并正确维护父子关系
    /// - Parameters:
    ///   - index: 要替换的节点索引
    ///   - child: 新的子节点
    /// - Returns: 被替换的原节点，如果索引无效则返回nil
    @discardableResult
    public func replaceChild(at index: Int, with child: XYBaseNode<T>) -> XYBaseNode<T>? {
        guard index >= 0 && index < children.count else { return nil }
        let oldChild = children[index]
        oldChild.parent = nil  // 断开旧连接
        children[index] = child
        child.parent = self
        // 更新被替换节点的 level
        child.level = level.isEmpty ? String(index) : "\(level).\(index)"
        child.refreshLevel()
        
        // 更新缓存
        removeFromCache(node: oldChild)
        buildCacheForSubtree(node: child)
        invalidateCache()
        return oldChild
    }
    
    // MARK: Query
    /// 根据索引查找子节点
    /// - Parameter index: 要查找的节点索引
    /// - Returns: 对应索引的子节点，如果索引无效则返回nil
    public func findChild(at index: Int) -> XYBaseNode<T>? {
        guard index >= 0 && index < children.count else { return nil }
        return children[index]
    }
    
    /// 查找指定范围内的子节点
    /// - Parameter range: 要查找的节点范围
    /// - Returns: 对应范围的子节点数组
    public func findChildren(in range: Range<Int>) -> [XYBaseNode<T>] {
        guard !children.isEmpty,
              range.lowerBound >= 0,
              range.upperBound <= children.count else { return [] }
        return Array(children[range])
    }
    
    /// 根据identifier查找节点（使用缓存优化）
    /// - Parameter identifier: 目标节点的identifier
    /// - Returns: 找到的节点，未找到返回nil
    public func findNode(withIdentifier identifier: String) -> XYBaseNode<T>? {
        buildCacheIfNeeded()
        return identifierCache[identifier]
    }
    
    /// 根据tag查找节点数组（使用缓存优化）
    /// - Parameter tag: 目标节点的tag
    /// - Returns: 包含该tag的所有节点数组
    public func findNodes(withTag tag: String) -> [XYBaseNode<T>] {
        buildCacheIfNeeded()
        return tagCache[tag] ?? []
    }
}

// MARK: - Cache Management
extension XYBaseNode {
    /// 构建子树的缓存
    private func buildCacheForSubtree(node: XYBaseNode<T>) {
        // 添加当前节点到缓存
        if let identifier = node.identifier {
            addToIdentifierCache(node: node, identifier: identifier)
        }
        
        for tag in node.tags {
            addToTagCache(node: node, tag: tag)
        }
        
        // 递归处理子节点
        for child in node.children {
            buildCacheForSubtree(node: child)
        }
    }
    
    /// 将节点添加到identifier缓存
    private func addToIdentifierCache(node: XYBaseNode<T>, identifier: XYIdentifier) {
        if let root = getRoot() {
            root.identifierCache[identifier] = node
        }
    }
    
    /// 从identifier缓存中移除节点
    private func removeFromIdentifierCache(node: XYBaseNode<T>, identifier: XYIdentifier) {
        if let root = getRoot() {
            root.identifierCache[identifier] = nil
        }
    }
    
    /// 将节点添加到tag缓存
    private func addToTagCache(node: XYBaseNode<T>, tag: XYTag) {
        if let root = getRoot() {
            if root.tagCache[tag] == nil {
                root.tagCache[tag] = []
            }
            // 避免重复添加同一个节点
            if !root.tagCache[tag]!.contains(where: { $0 === node }) {
                root.tagCache[tag]?.append(node)
            }
        }
    }
    
    /// 从tag缓存中移除节点
    private func removeFromTagCache(node: XYBaseNode<T>, tag: XYTag) {
        if let root = getRoot() {
            root.tagCache[tag]?.removeAll { $0 === node }
            // 如果tag对应的数组为空，则移除该tag
            if let tagArray = root.tagCache[tag], tagArray.isEmpty {
                root.tagCache[tag] = nil
            }
        }
    }
    
    /// 从所有缓存中移除节点
    private func removeFromCache(node: XYBaseNode<T>) {
        // 移除identifier缓存
        if let identifier = node.identifier {
            removeFromIdentifierCache(node: node, identifier: identifier)
        }
        
        // 移除tag缓存
        for tag in node.tags {
            removeFromTagCache(node: node, tag: tag)
        }
        
        // 递归处理子节点
        for child in node.children {
            removeFromCache(node: child)
        }
    }
    
    /// 获取根节点
    private func getRoot() -> XYBaseNode<T>? {
        var current: XYBaseNode<T>? = self
        while let parent = current?.parent {
            current = parent
        }
        return current
    }
    
    /// 如果需要，构建缓存
    private func buildCacheIfNeeded() {
        guard !isCacheValid, let root = getRoot() else { return }
        
        // 清空现有缓存
        root.identifierCache.removeAll()
        root.tagCache.removeAll()
        
        // 从根节点开始构建缓存
        root.buildCacheForSubtree(node: root)
        root.isCacheValid = true
    }
    
    /// 使缓存失效
    private func invalidateCache() {
        if let root = getRoot() {
            root.isCacheValid = false
        }
    }
}

// MARK: - Level Management
extension XYBaseNode {
    /// 刷新当前节点及其所有后代的 level 字符串
    /// 通常在树结构变更后调用（如移动节点）
    public func refreshLevel() {
        refreshLevelInternal()
    }
    
    private func refreshLevelInternal() {
        // 计算当前节点在父节点中的索引
        let indexInParent = parent?.children.firstIndex { $0 === self }
        
        // 构建 level 字符串
        if let parent = self.parent {
            let parentLevel = parent.level
            if let idx = indexInParent {
                self.level = parentLevel.isEmpty ? String(idx) : "\(parentLevel).\(idx)"
            } else {
                // 理论上不应发生（节点在父 children 中找不到自己）
                self.level = ""
            }
        } else {
            self.level = "" // root
        }

        // 递归刷新子节点
        for (index, child) in children.enumerated() {
            child.level = level.isEmpty ? String(index) : "\(level).\(index)"
            child.refreshLevelInternal()
        }
    }
    
    /// 为新插入的子节点更新 level（从 startIndex 开始的 count 个节点）
    private func updateLevelForNewChildren(startIndex: Int, count: Int) {
        for i in 0..<count {
            let childIndex = startIndex + i
            let child = children[childIndex]
            child.level = level.isEmpty ? String(childIndex) : "\(level).\(childIndex)"
            child.refreshLevelInternal() // 确保子树 level 正确
        }
    }
}

// MARK: - Tag
extension XYBaseNode {
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
}

// MARK: - Path & Relationship
extension XYBaseNode {
    /// 获取从根到当前节点的路径（包含自身）
    /// - Returns: 路径数组，索引 0 为根节点
    public func getPathToRoot() -> [XYBaseNode<T>] {
        var path: [XYBaseNode<T>] = []
        var current: XYBaseNode<T>? = self
        while let node = current {
            path.append(node)
            current = node.parent
        }
        return path.reversed()
    }
    
    /// 判断当前节点是否是指定节点的祖先
    public func isAncestor(of node: XYBaseNode<T>) -> Bool {
        var current: XYBaseNode<T>? = node.parent
        while let parent = current {
            if parent === self { return true }
            current = parent.parent
        }
        return false
    }
}

// MARK: - Find
extension XYBaseNode {
    /// 获取所有后代节点（递归，**不包含当前节点**）
    public func getAllDescendants() -> [XYBaseNode<T>] {
        var descendants: [XYBaseNode<T>] = []
        for child in children {
            descendants.append(child)
            descendants.append(contentsOf: child.getAllDescendants())
        }
        return descendants
    }
    
    /// 查找具有指定标识符的后代节点（深度优先）
    /// - Parameter identifier: 目标节点的 identifier
    /// - Returns: 找到的节点，未找到返回 nil
    public func findDescendant(withIdentifier identifier: String) -> XYBaseNode<T>? {
        for child in children {
            if child.identifier == identifier {
                return child
            }
            if let found = child.findDescendant(withIdentifier: identifier) {
                return found
            }
        }
        return nil
    }
}

// MARK: - Traverse
extension XYBaseNode {
    /// 深度优先遍历（DFS），从当前节点开始（从左到右顺序）
    /// - Parameter closure: 遍历回调，返回 `false` 表示停止遍历
    public func traverseDFS(_ closure: (XYBaseNode<T>) -> Bool) {
        var stack = [self]
        while let node = stack.popLast() {
            guard closure(node) else { return }
            // 反向插入以保持从左到右的遍历顺序
            stack.append(contentsOf: node.children.reversed())
        }
    }

    /// 广度优先遍历（BFS），从当前节点开始（从左到右顺序）
    /// - Parameter closure: 遍历回调，返回 `false` 表示停止遍历
    public func traverseBFS(_ closure: (XYBaseNode<T>) -> Bool) {
        var queue = [self]
        while let node = queue.first {
            queue.removeFirst()
            guard closure(node) else { return }
            queue.append(contentsOf: node.children)
        }
    }
}
