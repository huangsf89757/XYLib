//
//  XYDeviceStage.swift
//  XYCgms
//
//  Created by hsf on 2025/12/12.
//

// MARK: - Import
// System
import Foundation
// Basic
// Server
// Tool
// Business
// Third


// MARK: - XYDeviceStage
/// 设备生命阶段
public enum XYDeviceStage {
    case unpaired       // 未配对
    case paired         // 已配对
    case activated      // 已激活
    case preheated      // 已预热（激活后1小时内预热）
    case calibratable   // 可校准（激活后6小时内不可校准）
    case expired        // 已过期
}
