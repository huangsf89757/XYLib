//
//  XYCgmsLevel.swift
//  XYCgms
//
//  Created by hsf on 2025/8/27.
//

import Foundation

// MARK: - 血糖等级
public enum XYCgmsLevel: Int {
    case unknown    = -99   // 未知
    case limitHigh  = 2     // 高血糖（限制）
    case high       = 1     // 高血糖
    case normal     = 0     // 正常血糖
    case low        = -1    // 低血糖
    case urgentLow  = -2    // 紧急低血糖
    case limitLow   = -3    // 低血糖（限制）
}
