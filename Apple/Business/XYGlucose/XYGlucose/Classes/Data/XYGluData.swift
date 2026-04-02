//
//  XYGluData.swift
//  XYGlucose
//
//  Created by hsf on 2026/3/28.
//

import Foundation

// MARK: - XYGluData
/// 血糖数据
public struct XYGluData {
    /// ID
    public var id: String = UUID().uuidString
    /// 原始值
    public var rawValue: XYGluData.Value
    /// 平滑值
    public var smoothValue: XYGluData.Value?
    /// 趋势
    public var trend: XYGluData.Trend?
}
