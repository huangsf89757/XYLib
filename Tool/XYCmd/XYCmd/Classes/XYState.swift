//
//  XYState.swift
//  XYCmd
//
//  Created by hsf on 2025/9/16.
//

// MARK: - Import
// System
import Foundation
// Basic
// Server
// Tool
// Business
// Third


// MARK: - XYState
public enum XYState {
    case idle           // 空闲
    case executing      // 执行中
    case cancelled      // 主动取消
    case succeeded      // 执行成功
    case failed         // 执行失败
    
    
    public var code: Int {
        switch self {
        case .idle:             return 0
        case .executing:        return 1
        case .cancelled:        return 2
        case .succeeded:        return 3
        case .failed:           return 4
        }
    }
    
    public var isExecuting: Bool {
        self == .executing
    }
    
    public var isCompleted: Bool {
        self == .succeeded || self == .failed
    }
    
    public var isAbnormal: Bool {
        return self == .cancelled
    }
}

// MARK: - Equatable
extension XYState: Equatable {
    public static func == (lhs: XYState, rhs: XYState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.executing, .executing),
             (.cancelled, .cancelled),
             (.succeeded, .succeeded),
             (.failed, .failed):
            return true
        default:
            return false
        }
    }
}

// MARK: - Hashable
extension XYState: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .idle: hasher.combine("idle")
        case .executing: hasher.combine("executing")
        case .cancelled: hasher.combine("cancelled")
        case .succeeded: hasher.combine("succeeded")
        case .failed: hasher.combine("failed")
        }
    }
}
