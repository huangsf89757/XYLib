//
//  XYCgmsUnit.swift
//  XYCgms
//
//  Created by hsf on 2025/8/27.
//

import Foundation

// MARK: - 血糖单位
// 1 mmol/L = 18 mg/dL
public enum XYCgmsUnit {
    case mg     // 基准
    case mmol
}

public extension XYCgmsUnit {
    /// 单位描述
    var desc: String {
        switch self {
        case .mg:
            return "mg/dL"
        case .mmol:
            return "mmol/L"
        }
    }
}

