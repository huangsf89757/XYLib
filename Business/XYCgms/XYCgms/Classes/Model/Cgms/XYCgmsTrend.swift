//
//  XYCgmsTrend.swift
//  XYCgms
//
//  Created by hsf on 2025/8/27.
//

import Foundation

// MARK: - 血糖趋势
public typealias XYCgmsTrend = Float

public extension XYCgmsTrend {
    /// 趋势类型
    var type: MTCgmsTrendType {
        if self < -127 {
            return .unknown
        } else if self >= -127 && self < -30 {
            return .dropQuick
        } else if self >= -30 && self < -20 {
            return .drop
        } else if self >= -20 && self < -10 {
            return .dropSlow
        } else if self >= -10 && self < 10 {
            return .stable
        } else if self >= 10 && self < 20 {
            return .riseSlow
        } else if self >= 20 && self < 30 {
            return .rise
        } else if self >= 30 && self < 127 {
            return .riseQuick
        } else {
            return .unknown
        }
    }
}

// MARK: - 血糖趋势类型
public enum MTCgmsTrendType: Int {
    case unknown    = -99   // 未知
    case dropQuick  = -3    // 快速下降
    case drop       = -2    // 下降
    case dropSlow   = -1    // 缓慢下降
    case stable     = 0     // 血糖平稳
    case riseSlow   = 1     // 缓慢上升
    case rise       = 2     // 上升
    case riseQuick  = 3     // 快速上升
}
