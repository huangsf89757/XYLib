//
//  XYCgmsThreshold.swift
//  XYCgms
//
//  Created by hsf on 2025/8/28.
//

import Foundation

// MARK: - 血糖阈值
public struct XYCgmsThreshold {
    // 高血糖（限制）
    let limitHigh: XYCgmsValue
    // 高血糖（紧急）
    let urgentHigh: XYCgmsValue
    // 高血糖
    let high: XYCgmsValue
    // 低血糖
    let low: XYCgmsValue
    // 低血糖（紧急）
    let urgentLow: XYCgmsValue
    // 低血糖（限制）
    let limitLow: XYCgmsValue
    
    /// 默认的血糖阈值
    static let `default` = XYCgmsThreshold(limitHigh: 450.0, urgentHigh: 360.0, high: 180.0, low: 70.2, urgentLow: 59.4, limitLow: 36.0)
}
