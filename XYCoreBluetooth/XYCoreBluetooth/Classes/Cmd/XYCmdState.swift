//
//  XYCmdState.swift
//  Pods
//
//  Created by hsf on 2025/9/16.
//

import Foundation

// MARK: - XYCmdState
public enum XYCmdState {
    case idle
    case executing
    case succeeded
    case failed
    case cancelled
}
extension XYCmdState: Equatable {
    public static func == (lhs: XYCmdState, rhs: XYCmdState) -> Bool {
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
extension XYCmdState: Hashable {
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
