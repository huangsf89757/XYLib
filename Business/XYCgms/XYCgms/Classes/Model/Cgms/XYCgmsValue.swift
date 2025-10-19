//
//  XYCgmsValue.swift
//  XYCgms
//
//  Created by hsf on 2025/8/27.
//

import Foundation

// MARK: - 血糖基准值
// 以mg/dL为基准
public typealias XYCgmsValue = Double

public extension XYCgmsValue {
    /// mg/dL 对应的 基准单位值
    var mg: Double { self }
    /// mmol/L 对应的 基准单位值
    var mmol: Double { self / 18.0 }
}

