//
//  XYError.swift
//  Pods
//
//  Created by hsf on 2025/9/16.
//

import Foundation

// MARK: - XYError
public enum XYError: Error {
    case timeout                    // 命令操作超时
    case cancelled                  // 命令被取消
    case executing                  // 命令正在执行
    case maxRetryExceeded           // 超出最大重试次数
    case notImplemented             // 子类未实现 run
    case other(Error?)              // 其他错误
    case unknown(Error?)            // 未知错误
    
    public var info: String {
        switch self {
        case .timeout: return "timeout"
        case .cancelled: return "cancelled"
        case .executing: return "executing"
        case .maxRetryExceeded: return "maxRetryExceeded"
        case .notImplemented: return "notImplemented"
        case .other(let error):
            return error?.localizedDescription ?? "other"
        case .unknown(let error):
            return error?.localizedDescription ?? "unknown"
        }
    }
}
extension XYError: Equatable {
    public static func == (lhs: XYError, rhs: XYError) -> Bool {
        switch (lhs, rhs) {
        case (.timeout, .timeout),
             (.cancelled, .cancelled),
             (.executing, .executing),
             (.maxRetryExceeded, .maxRetryExceeded),
             (.notImplemented, .notImplemented):
            return true
        case let (.other(lhsErr), .other(rhsErr)),
             let (.unknown(lhsErr), .unknown(rhsErr)):
            guard let lhsErr = lhsErr as NSError?, let rhsErr = rhsErr as NSError? else {
                return lhsErr == nil && rhsErr == nil
            }
            return lhsErr.domain == rhsErr.domain && lhsErr.code == rhsErr.code
        default:
            return false
        }
    }
}
extension XYError: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .timeout: hasher.combine("timeout")
        case .cancelled: hasher.combine("cancelled")
        case .executing: hasher.combine("executing")
        case .maxRetryExceeded: hasher.combine("maxRetryExceeded")
        case .notImplemented: hasher.combine("notImplemented")
        case .other(let error), .unknown(let error):
            if let err = error as NSError? {
                hasher.combine(err.domain)
                hasher.combine(err.code)
            } else {
                hasher.combine("nil")
            }
        }
    }
}
