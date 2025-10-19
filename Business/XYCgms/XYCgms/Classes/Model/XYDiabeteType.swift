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
    /// 血糖阈值
    /*
     | 类型 | 原始范围 (mmol/L) | 换算后范围 (mg/dL) |
     |------|------------------|--------------------|
     | 未确诊 / 糖耐量正常 | 3.9 – 7.8 mmol/L | 70.2 – 140.4 mg/dL |
     | 1型糖尿病 (T1DM) | 3.9 – 10.0 mmol/L | 70.2 – 180.0 mg/dL |
     | 2型糖尿病 (T2DM) | 3.9 – 10.0 mmol/L | 70.2 – 180.0 mg/dL |
     | 妊娠糖尿病 | 3.5 – 7.8 mmol/L | 63.0 – 140.4 mg/dL |
     | 其他糖尿病类型 | 3.9 – 10.0 mmol/L | 70.2 – 180.0 mg/dL |
     */
    var threshold: XYCgmsThreshold {
        switch self {
        case .unknown:
            return XYCgmsThreshold.default
        case .t1dm:
            return XYCgmsThreshold(limitHigh: 450.0, urgentHigh: 360.0, high: 180.0, low: 70.2, urgentLow: 59.4, limitLow: 36.0)
        case .t2dm:
            return XYCgmsThreshold(limitHigh: 450.0, urgentHigh: 360.0, high: 180.0, low: 70.2, urgentLow: 59.4, limitLow: 36.0)
        case .gestation:
            return XYCgmsThreshold(limitHigh: 450.0, urgentHigh: 360.0, high: 140.4, low: 63.0, urgentLow: 59.4, limitLow: 36.0)
        case .other:
            return XYCgmsThreshold(limitHigh: 450.0, urgentHigh: 360.0, high: 180.0, low: 70.2, urgentLow: 59.4, limitLow: 36.0)
        }
    }
}
