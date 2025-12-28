//
//  XYDiabeteType.swift
//  XYCgms
//
//  Created by hsf on 2025/9/4.
//

// MARK: - Import
// System
import Foundation
// Basic
// Server
// Tool
// Business
// Third


// MARK: - XYDiabeteType
/// 糖尿病类型
/*
 | 类型 | 原始范围 (mmol/L) | 换算后范围 (mg/dL) |
 |------|------------------|--------------------|
 | 未确诊 / 糖耐量正常 | 3.9 – 7.8 mmol/L | 70.2 – 140.4 mg/dL |
 | 1型糖尿病 (T1DM) | 3.9 – 10.0 mmol/L | 70.2 – 180.0 mg/dL |
 | 2型糖尿病 (T2DM) | 3.9 – 10.0 mmol/L | 70.2 – 180.0 mg/dL |
 | 妊娠糖尿病 | 3.5 – 7.8 mmol/L | 63.0 – 140.4 mg/dL |
 | 其他糖尿病类型 | 3.9 – 10.0 mmol/L | 70.2 – 180.0 mg/dL |
 */
public enum XYDiabeteType: Int, CaseIterable {
    case unknown        = 0     // 未确诊/糖耐量正常
    case t1dm           = 1     // 1型糖尿病
    case t2dm           = 2     // 2型糖尿病
    case gestation      = 3     // 妊娠糖尿病
    case other          = -99   // 其他
}

public extension XYDiabeteType {
    /// 血糖目标范围阈值
    var tirTrhreshold: XYTirThreshold {
        switch self {
        case .unknown:
            return XYTirThreshold.default
        case .t1dm:
            return XYTirThreshold(limitHigh: XYCgmsValue(mg: 450.0), high: XYCgmsValue(mg: 180.0), low: XYCgmsValue(mg: 70.2), limitLow: XYCgmsValue(mg: 36.0))
        case .t2dm:
            return XYTirThreshold(limitHigh: XYCgmsValue(mg: 450.0), high: XYCgmsValue(mg: 180.0), low: XYCgmsValue(mg: 70.2), limitLow: XYCgmsValue(mg: 36.0))
        case .gestation:
            return XYTirThreshold(limitHigh: XYCgmsValue(mg: 450.0), high: XYCgmsValue(mg: 140.4), low: XYCgmsValue(mg: 63.0), limitLow: XYCgmsValue(mg: 36.0))
        case .other:
            return XYTirThreshold(limitHigh: XYCgmsValue(mg: 450.0), high: XYCgmsValue(mg: 180.0), low: XYCgmsValue(mg: 70.2), limitLow: XYCgmsValue(mg: 36.0))
        }
    }
    /// 血糖提醒阈值
    var alertThreshold: XYAlertThreshold {
        switch self {
        case .unknown:
            return XYAlertThreshold.default
        case .t1dm:
            return XYAlertThreshold(urgentHigh: XYCgmsValue(mg: 360.0), high: XYCgmsValue(mg: 180.0), low: XYCgmsValue(mg: 70.2), urgentLow: XYCgmsValue(mg: 59.4))
        case .t2dm:
            return XYAlertThreshold(urgentHigh: XYCgmsValue(mg: 360.0), high: XYCgmsValue(mg: 180.0), low: XYCgmsValue(mg: 70.2), urgentLow: XYCgmsValue(mg: 59.4))
        case .gestation:
            return XYAlertThreshold(urgentHigh: XYCgmsValue(mg: 360.0), high: XYCgmsValue(mg: 140.4), low: XYCgmsValue(mg: 63.0), urgentLow: XYCgmsValue(mg: 59.4))
        case .other:
            return XYAlertThreshold(urgentHigh: XYCgmsValue(mg: 360.0), high: XYCgmsValue(mg: 180.0), low: XYCgmsValue(mg: 70.2), urgentLow: XYCgmsValue(mg: 59.4))
        }
    }
}
