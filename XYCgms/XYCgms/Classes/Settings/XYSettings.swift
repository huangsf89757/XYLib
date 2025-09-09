//
//  XYSettings.swift
//  XYCgms
//
//  Created by hsf on 2025/8/27.
//

import Foundation

// MARK: - 设置
public final class XYSettings {
    // MARK: var
    /// 通用设置
    public private(set) var general = XYGeneralSettings()
    /// 目标范围
    public private(set) var targetRange = XYTargetSettings()
    /// 提醒设置
    public private(set) var warning = XYWarningSettings()
    /// 系统设置
    public private(set) var system = XYSystemSettings()
}
