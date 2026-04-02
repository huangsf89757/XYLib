//
//  XYGluTir.swift
//  XYGlucose
//
//  Created by hsf on 2026/3/31.
//

import Foundation

// MARK: - XYGluAlert
/// 血糖提醒
public struct XYGluTir {
    /// 高血糖（限制）
    let limitHigh: XYGluTir.Content
    /// 高血糖
    let high: XYGluTir.Content
    /// 低血糖
    let low: XYGluTir.Content
    /// 低血糖（限制）
    let limitLow: XYGluTir.Content
}
