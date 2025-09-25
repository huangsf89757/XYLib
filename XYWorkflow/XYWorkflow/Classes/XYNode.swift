//
//  XYNode.swift
//  Pods
//
//  Created by hsf on 2025/9/16.
//

import Foundation
import XYLog

// MARK: - XYNode
open class XYNode<ResultType>: XYCmd<ResultType> {
    /// 子节点
    public var next: XYNode?
    /// 父节点
    public weak var prev: XYNode?
    
    public init(id: String = UUID().uuidString,
                timeout: TimeInterval = 10,
                next: XYNode? = nil,
                prev: XYNode? = nil) {
        self.next = next
        self.prev = prev
        super.init(id: id, timeout: timeout)
        self.logTag = "WorkFlow.Node"
    }
}
