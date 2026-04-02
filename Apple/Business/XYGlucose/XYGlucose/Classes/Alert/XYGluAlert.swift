//
//  XYGluAlert.swift
//  XYGlucose
//
//  Created by hsf on 2026/3/31.
//

import Foundation

// MARK: - XYGluAlert
/// 血糖提醒
public struct XYGluAlert {
    // MARK: var
    /// 总开关，默认开启
    public var enable = true
    
    /// 高血糖提醒（紧急）
    public private(set) lazy var urgentHigh: XYGluAlert.Content = {
        var content = XYGluAlert.Content()
        content.threshold = 360.0.mg
        return content
    }()
    /// 高血糖提醒
    public private(set) lazy var high: XYGluAlert.Content = {
        var content = XYGluAlert.Content()
        content.threshold = 180.0.mg
        return content
    }()
    /// 低血糖提醒
    public private(set) lazy var low: XYGluAlert.Content = {
        var content = XYGluAlert.Content()
        content.threshold = 70.2.mg
        return content
    }()
    /// 低血糖提醒（紧急）
    public private(set) lazy var urgentLow: XYGluAlert.Content = {
        var content = XYGluAlert.Content()
        content.threshold = 59.4.mg
        return content
    }()
    
    /// 血糖上升过快提醒
    public private(set) lazy var riseQuickly: XYGluAlert.Content = {
        let content = XYGluAlert.Content()
        return content
    }()
    /// 血糖下降过快提醒
    public private(set) lazy var dropQuickly: XYGluAlert.Content = {
        let content = XYGluAlert.Content()
        return content
    }()
    
    /// 信号丢失提醒
    public private(set) lazy var singleLost: XYGluAlert.Content = {
        let content = XYGluAlert.Content()
        return content
    }()
}

extension XYGluAlert {
    /// 获取提醒设置开关状态
    public func checkEnable(for setting: XYGluAlert.Content) -> Bool {
        return enable && setting.enable
    }
}
