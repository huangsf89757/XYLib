//
//  XYSettings.swift
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


// MARK: - XYSettings
/// CGMS设置
public final class XYSettings {
    // MARK: shared
    public static let shared = XYSettings()
    private init() {}
    
    // MARK: var
    /// 通用设置
    public private(set) var general = XYGeneralSettings()
    /// 血糖目标范围设置
    public private(set) var tir = XYTirSettings()
    /// 血糖提醒设置
    public private(set) var alert = XYAlertSettings()
    /// 系统设置
    public private(set) var system = XYSystemSettings()
}




