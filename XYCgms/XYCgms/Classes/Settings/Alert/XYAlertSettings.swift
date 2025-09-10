//
//  XYAlertSettings.swift
//  XYCgms
//
//  Created by hsf on 2025/8/27.
//

import Foundation

// MARK: - 血糖提醒设置
public final class XYAlertSettings {
    // MARK: var
    /// 总开关，默认开启
    public var enable = true
    /// 极高血糖提醒
    public private(set) lazy var extremeHigh: XYAlertSettingContent = {
        let content = XYAlertSettingContent()
        return content
    }()
    /// 高血糖提醒
    public private(set) lazy var high: XYAlertSettingContent = {
        let content = XYAlertSettingContent()
        return content
    }()
    /// 低血糖提醒
    public private(set) lazy var low: XYAlertSettingContent = {
        let content = XYAlertSettingContent()
        return content
    }()
    /// 低血糖紧急提醒
    public private(set) lazy var urgentLow: XYAlertSettingContent = {
        let content = XYAlertSettingContent()
        return content
    }()
    /// 血糖上升过快提醒
    public private(set) lazy var riseQuickly: XYAlertSettingContent = {
        let content = XYAlertSettingContent()
        return content
    }()
    /// 血糖下降过快提醒
    public private(set) lazy var dropQuickly: XYAlertSettingContent = {
        let content = XYAlertSettingContent()
        return content
    }()
    /// 信号丢失提醒
    public private(set) lazy var singleLost: XYAlertSettingContent = {
        let content = XYAlertSettingContent()
        return content
    }()
}

extension XYAlertSettings {
    /// 获取提醒设置开关状态
    public func checkEnable(for setting: XYAlertSettingContent) -> Bool {
        return enable && setting.enable
    }
}
