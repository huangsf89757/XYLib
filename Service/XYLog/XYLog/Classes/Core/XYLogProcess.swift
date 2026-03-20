//
//  XYLogProcess.swift
//  XYLog
//
//  Created by hsf on 2025/9/2.
//

import Foundation

// MARK: - XYLogProcess
public enum XYLogProcess {
    case begin              // 开始
    case doing              // 过程中
    case succ               // 成功
    case fail               // 失败
    case unknown            // 未知
    
    public var tag: String {
        switch self {
        case .begin:
            return "B"
        case .doing:
            return "D"
        case .succ:
            return "S"
        case .fail:
            return "F"
        case .unknown:
            return "U"
        }
    }
    
    public var symbol: String {
        switch self {
        case .begin:
            return "🔫"
        case .doing:
            return "🏃🏻‍➡️"
        case .succ:
            return "👏🏻"
        case .fail:
            return "🏳️"
        case .unknown:
            return "🤷🏻"
        }
    }
}
