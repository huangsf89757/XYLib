//
//  XYWarningSettingContent.swift
//  XYCgms
//
//  Created by hsf on 2025/8/27.
//

import Foundation

// MARK: - 提醒设置内容
public final class XYWarningSettingContent {
    // MARK: var
    /// 开关，默认开启
    public var enable = true
    /// 阈值，默认0
    public var threshold: Float = 0
    /// 提醒方式，默认声音和振动
    public var method: XYAlertMethod = [.sound, .vibration]
    /// 提醒间隔，默认15分钟
    public var interval: TimeInterval = 15 * 60
    /// 提醒时长，默认2秒
    public var duration: TimeInterval = 2
    
}
