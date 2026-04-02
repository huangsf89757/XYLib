//
//  XYGluDeviceStage.swift
//  XYCgms
//
//  Created by hsf on 2025/12/12.
//

import Foundation

// MARK: - XYGluDeviceStage
/// 设备生命阶段
extension XYGluDevice {
    public enum Stage: Int {
        case unpaired       = 0 // 未配对
        case paired         = 1 // 已配对
        case activated      = 2 // 已激活
        case preheated      = 3 // 已预热（激活后1小时内预热）
        case calibratable   = 4 // 可校准（激活后6小时内不可校准）
        case expired        = 5 // 已过期
    }
}
