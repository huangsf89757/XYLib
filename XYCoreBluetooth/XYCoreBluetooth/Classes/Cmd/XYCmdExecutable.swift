//
//  XYCmdExecutable.swift
//  Pods
//
//  Created by hsf on 2025/9/16.
//

import Foundation

public protocol XYCmdExecutable: AnyObject {
    associatedtype ResultType
    var id: String { get }
    var state: XYCmdState { get }
    func execute() async throws -> ResultType
    func cancel()
    
    /// 子节点（预留，当前未使用）
    var next: XYCmdExecutable? { get set }
    /// 父节点 (使用 weak 避免循环引用，预留)
    var prev: XYCmdExecutable? { get set }
}

