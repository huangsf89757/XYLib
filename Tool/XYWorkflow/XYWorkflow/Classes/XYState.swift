//
//  XYState.swift
//  Pods
//
//  Created by hsf on 2025/9/16.
//

import Foundation

// MARK: - XYState
public enum XYState {
    case idle
    case executing
    case succeeded
    case failed
    case cancelled
}
extension XYState: Equatable {
    public static func == (lhs: XYState, rhs: XYState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.executing, .executing),
             (.succeeded, .succeeded),
             (.failed, .failed),
             (.cancelled, .cancelled):
            return true
        default:
            return false
        }
    }
}
extension XYState: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .idle: hasher.combine("idle")
        case .executing: hasher.combine("executing")
        case .succeeded: hasher.combine("succeeded")
        case .cancelled: hasher.combine("cancelled")
        case .failed: hasher.combine("failed")
        }
    }
}
