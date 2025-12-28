//
//  XYTirThreshold.swift
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


// MARK: - XYTirThreshold
/// 血糖目标范围阈值
public struct XYTirThreshold {
    /// 高血糖（限制）
    /// 超过的部分显示「高」
    let limitHigh: XYCgmsValue
    /// 高血糖
    let high: XYCgmsValue
    /// 低血糖
    let low: XYCgmsValue
    /// 低血糖（限制）
    /// 超过的部分显示「低」
    let limitLow: XYCgmsValue
    /// 默认的血糖阈值
    static let `default` = XYTirThreshold(limitHigh: XYCgmsValue(mg: 450.0),
                                          high: XYCgmsValue(mg: 180.0),
                                          low: XYCgmsValue(mg: 70.2),
                                          limitLow: XYCgmsValue(mg: 36.0))
}

