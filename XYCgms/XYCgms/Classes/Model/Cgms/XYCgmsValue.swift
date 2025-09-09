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

public extension XYCgmsValue {
    /// mg/dL 对应的 基准单位值（在Chart中可见的）
    var visibleMg: Double {
        if self > limitHigh {
            return limitHigh
        }
        else if self < limitLow {
            return limitLow
        }
        else {
            return self
        }
    }
    /// mmol/L 对应的 基准单位值（在Chart中可见的）
    var visibleMmol: Double { visibleMg / 18.0 }
}

public extension XYCgmsValue {
    /// 限制高血糖临界值
    var limitHigh: XYCgmsValue {
        600
    }
    /// 紧急低血糖临界值
    var urgentLow: XYCgmsValue {
        54
    }
    /// 限制低血糖临界值
    var limitLow: XYCgmsValue {
        36
    }
}

public extension XYCgmsValue {
    /// 获取血糖等级
    /// - Parameter targetRange: 血糖目标范围
    /// - Returns: 血糖等级
    func level(for targetRange: XYCgmsTargetRange) -> XYCgmsLevel {
        if self > limitHigh {
            return .limitHigh // ( ?
        }
        else if self > targetRange.high {
            return .high // (]
        }
        else if self >= targetRange.low {
            return .normal // []
        }
        else if self >= urgentLow {
            return .low // [)
        }
        else if self >= limitLow {
            return .urgentLow // [)
        }
        else {
            return .limitLow // ? )
        }
    }
}

