//
//  XYGluDataTrend.swift
//  XYGlucose
//
//  Created by hsf on 2026/3/28.
//

import Foundation

// MARK: - XYGluData.Trend
/// 血糖趋势
extension XYGluData {
    public enum Trend: Int {
        case unknown    = -99   // 未知
        case dropQuick  = -3    // 快速下降
        case drop       = -2    // 下降
        case dropSlow   = -1    // 缓慢下降
        case stable     = 0     // 血糖平稳
        case riseSlow   = 1     // 缓慢上升
        case rise       = 2     // 上升
        case riseQuick  = 3     // 快速上升
        
        // MARK: life cycle
        public init(value: Float) {
            self = switch value {
            case ..<(-127):         .unknown
            case (-127)..<(-30):    .dropQuick
            case (-30)..<(-20):     .drop
            case (-20)..<(-10):     .dropSlow
            case (-10)..<10:        .stable
            case 10..<20:           .riseSlow
            case 20..<30:           .rise
            case 30..<127:          .riseQuick
            default:                .unknown
            }
        }
    }
}

// MARK: - Float
public extension Float {
    var trend: XYGluData.Trend { XYGluData.Trend(value: self) }
}
