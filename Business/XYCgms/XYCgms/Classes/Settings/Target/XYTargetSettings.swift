//
//  XYTargetSettings.swift
//  XYCgms
//
//  Created by hsf on 2025/8/28.
//

import Foundation

// MARK: - 血糖目标范围设置
public final class XYTargetSettings {
    /// 示例
    public let example = XYDiabeteType.allCases
    /// 血糖类型
    public var diabeteType: XYDiabeteType? {
        didSet {
            targetRange = diabeteType?.targetRange
        }
    }
    /// 目标范围
    public var targetRange: XYCgmsTargetRange?
}


