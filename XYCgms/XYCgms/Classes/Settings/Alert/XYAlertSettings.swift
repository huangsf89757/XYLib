//
//  XYWarningSettings.swift
//  XYCgms
//
//  Created by hsf on 2025/8/27.
//

import Foundation

// MARK: - 血糖提醒设置
public final class XYWarningSettings {
    // MARK: var
    /// 高血糖提醒
    public private(set) lazy var high: XYWarningSettingContent = {
        let content = XYWarningSettingContent()
        return content
    }()
    /// 低血糖提醒
    public private(set) lazy var low: XYWarningSettingContent = {
        let content = XYWarningSettingContent()
        return content
    }()
    /// 低血糖紧急提醒
    public private(set) lazy var urgentLow: XYWarningSettingContent = {
        let content = XYWarningSettingContent()
        return content
    }()
    /// 血糖上升过快提醒
    public private(set) lazy var riseQuickly: XYWarningSettingContent = {
        let content = XYWarningSettingContent()
        return content
    }()
    /// 血糖下降过快提醒
    public private(set) lazy var dropQuickly: XYWarningSettingContent = {
        let content = XYWarningSettingContent()
        return content
    }()
    /// 信号丢失提醒
    public private(set) lazy var singleLost: XYWarningSettingContent = {
        let content = XYWarningSettingContent()
        return content
    }()
}
