//
//  XYDiabeteType.swift
//  XYCgms
//
//  Created by hsf on 2025/9/4.
//

import Foundation

// MARK: - 糖尿病类型
public enum XYDiabeteType: Int, CaseIterable {
    case unknown        = 0     // 未确诊/糖耐量正常
    case t1dm           = 1     // 1型糖尿病
    case t2dm           = 2     // 2型糖尿病
    case gestation      = 3     // 妊娠糖尿病
    case other          = -99   // 其他
}

public extension XYDiabeteType {
    /// 血糖目标范围
    var targetRange: XYCgmsTargetRange {
        switch self {
        case .unknown:
            return XYCgmsTargetRange(high: 70.2, low: 140.4)
        case .t1dm:
            return XYCgmsTargetRange(high: 70.2, low: 180.0)
        case .t2dm:
            return XYCgmsTargetRange(high: 70.2, low: 180.0)
        case .gestation:
            return XYCgmsTargetRange(high: 63, low: 140.4)
        case .other:
            return XYCgmsTargetRange(high: 70.2, low: 180.0)
        }
    }
}
