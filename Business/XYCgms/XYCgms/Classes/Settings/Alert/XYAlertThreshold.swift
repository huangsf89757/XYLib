//
//  XYAlertThreshold.swift
//  XYCgms
//
//  Created by hsf on 2025/8/28.
//

// MARK: - Import
// System
import Foundation
// Basic
// Server
// Tool
// Business
// Third


// MARK: - XYAlertThreshold
/// 血糖提醒阈值
public struct XYAlertThreshold {
    /// 高血糖（紧急）
    let urgentHigh: XYCgmsValue
    /// 高血糖
    let high: XYCgmsValue
    /// 低血糖
    let low: XYCgmsValue
    /// 低血糖（紧急）
    let urgentLow: XYCgmsValue
    
    /// 默认的血糖阈值
    static let `default` = XYAlertThreshold(urgentHigh: XYCgmsValue(mg: 360.0),
                                            high: XYCgmsValue(mg: 180.0),
                                            low: XYCgmsValue(mg: 70.2),
                                            urgentLow: XYCgmsValue(mg: 59.4))
}
