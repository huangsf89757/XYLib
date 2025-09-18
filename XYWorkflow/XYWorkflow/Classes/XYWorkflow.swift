//
//  XYWorkflow.swift
//  Pods
//
//  Created by hsf on 2025/9/16.
//

import Foundation
import XYLog


// MARK: - XYWorkflow
open class XYWorkflow<ResultType>: XYCmd<ResultType> {
    public let root: XYNode<Any?>
    public init(id: String = UUID().uuidString,
                timeout: TimeInterval = 10,
                root: XYNode<Any?>) {
        self.root = root
        super.init(id: id, timeout: timeout)
        self.logTag = "Flow.W"
    }
}
