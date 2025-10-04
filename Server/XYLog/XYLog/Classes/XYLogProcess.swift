//
//  XYLogProcess.swift
//  XYLog
//
//  Created by hsf on 2025/9/2.
//

import Foundation

public enum XYLogProcess {
    case begin              // 开始
    case doing              // 过程中
    case succ               // 成功
    case fail               // 失败
    
    public var desc: String {
        switch self {
        case .begin:
            return "$B"
        case .doing:
            return "$D"
        case .succ:
            return "$S"
        case .fail:
            return "$F"
        }
    }
}
