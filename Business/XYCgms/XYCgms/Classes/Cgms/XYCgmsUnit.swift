//
//  XYCgmsUnit.swift
//  XYCgms
//
//  Created by hsf on 2025/8/27.
//

// MARK: - Import
// System
import Foundation
// Basic
// Server
// Tool
// Business
// Third


// MARK: - XYCgmsUnit
/// 血糖单位
/// 1 mmol/L = 18 mg/dL
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

