//
//  XYGlucoseSettings.swift
//  XYCgms
//
//  Created by hsf on 2025/8/28.
//

import Foundation

// MARK: - 血糖设置
public final class XYGlucoseSettings {
    /// 血糖类型
    public var diabeteType: XYDiabeteType = .unknown
    /// 血糖阈值
    public var threshold: XYCgmsThreshold = .default
}


