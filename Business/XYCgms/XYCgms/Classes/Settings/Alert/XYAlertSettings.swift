//
//  XYAlertSettings.swift
//  XYCgms
//
//  Created by hsf on 2025/8/27.
//

// MARK: - Import
// System
import Foundation
// Basic
// Server
// Tool
// Business
// Third


// MARK: - XYAlertThreshold
/// 血糖提醒设置
public final class XYAlertSettings {
    // MARK: var
    /// 总开关，默认开启
    public var enable = true
    /// 高血糖提醒（紧急）
    public private(set) lazy var urgentHigh: XYAlertContent = {
        let content = XYAlertContent()
        content.threshold = XYAlertThreshold.default.urgentHigh
        return content
    }()
    /// 高血糖提醒
    public private(set) lazy var high: XYAlertContent = {
        let content = XYAlertContent()
        content.threshold = XYAlertThreshold.default.high
        return content
    }()
    /// 低血糖提醒
    public private(set) lazy var low: XYAlertContent = {
        let content = XYAlertContent()
        content.threshold = XYAlertThreshold.default.low
        return content
    }()
    /// 低血糖提醒（紧急）
    public private(set) lazy var urgentLow: XYAlertContent = {
        let content = XYAlertContent()
        content.threshold = XYAlertThreshold.default.urgentLow
        return content
    }()
    /// 血糖上升过快提醒
    public private(set) lazy var riseQuickly: XYAlertContent = {
        let content = XYAlertContent()
        return content
    }()
    /// 血糖下降过快提醒
    public private(set) lazy var dropQuickly: XYAlertContent = {
        let content = XYAlertContent()
        return content
    }()
    /// 信号丢失提醒
    public private(set) lazy var singleLost: XYAlertContent = {
        let content = XYAlertContent()
        return content
    }()
}

extension XYAlertSettings {
    /// 获取提醒设置开关状态
    public func checkEnable(for setting: XYAlertContent) -> Bool {
        return enable && setting.enable
    }
}
