//
//  XYError.swift
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


// MARK: - XYError
public enum XYError: Error {
    case reject                     // 拒绝执行
    case zombie                     // 内存泄露
    case unexpected                 // 不符合预期的
    case timeout                    // 命令操作超时
    case cancelled                  // 命令被取消
    case maxRetryExceeded           // 超出最大重试次数
    case cannotRetryError           // 不可重试错误
    case notImplemented             // 子类未实现 run
    case other(Error?)              // 其他错误
    
    public var info: String {
        var desc = ""
        switch self {
        case .reject:               desc = "reject"
        case .zombie:               desc = "zombie"
        case .unexpected:           desc = "unexpected"
        case .timeout:              desc = "timeout"
        case .cancelled:            desc = "cancelled"
        case .maxRetryExceeded:     desc = "maxRetryExceeded"
        case .cannotRetryError:     desc = "cannotRetryError"
        case .notImplemented:       desc = "notImplemented"
        case .other(let error):     desc = error?.localizedDescription ?? "other"
        }
        return "\(desc)(\(code))"
    }
    
    public var code: Int {
        switch self {
        case .reject:               return 1
        case .zombie:               return 2
        case .unexpected:           return 3
        case .timeout:              return 4
        case .cancelled:            return 5
        case .maxRetryExceeded:     return 6
        case .cannotRetryError:     return 7
        case .notImplemented:       return 8
        case .other:                return 0
        }
    }
}


// MARK: - Equatable
extension XYError: Equatable {
    public static func == (lhs: XYError, rhs: XYError) -> Bool {
        switch (lhs, rhs) {
        case (.reject, .reject),
             (.zombie, .zombie),
             (.unexpected, .unexpected),
             (.timeout, .timeout),
             (.cancelled, .cancelled),
             (.maxRetryExceeded, .maxRetryExceeded),
             (.cannotRetryError, .cannotRetryError),
             (.notImplemented, .notImplemented):
            return true
        case let (.other(lhsErr), .other(rhsErr)):
            // 处理nil错误的情况
            if lhsErr == nil && rhsErr == nil {
                return true
            }
            // 处理NSError类型的错误
            guard let lhsNSError = lhsErr as NSError?, let rhsNSError = rhsErr as NSError? else {
                return false
            }
            return lhsNSError.domain == rhsNSError.domain && lhsNSError.code == rhsNSError.code
        default:
            return false
        }
    }
}


// MARK: - Hashable
extension XYError: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .reject:               hasher.combine("reject")
        case .zombie:               hasher.combine("zombie")
        case .unexpected:           hasher.combine("unexpected")
        case .timeout:              hasher.combine("timeout")
        case .cancelled:            hasher.combine("cancelled")
        case .maxRetryExceeded:     hasher.combine("maxRetryExceeded")
        case .cannotRetryError:     hasher.combine("cannotRetryError")
        case .notImplemented:       hasher.combine("notImplemented")
        case .other(let error):
            if let err = error as NSError? {
                hasher.combine(err.domain)
                hasher.combine(err.code)
            } else {
                hasher.combine("nil")
            }
        }
    }
}
