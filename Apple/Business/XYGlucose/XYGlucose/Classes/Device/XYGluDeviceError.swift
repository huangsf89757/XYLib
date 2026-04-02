//
//  XYGluDeviceError.swift
//  XYCgms
//
//  Created by hsf on 2025/12/12.
//

import Foundation

// MARK: - XYGluDevice.Error
/// 设备错误
extension XYGluDevice {
    public enum Error {
        case abnormal       // 异常（可恢复）
        case fault          // 故障
    }
}
