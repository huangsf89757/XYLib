//
//  XYGluDeviceLog.swift
//  XYCgms
//
//  Created by hsf on 2025/12/12.
//

import Foundation

// MARK: - XYGluDeviceLog
/// 设备日志
extension XYGluDevice {
    public struct Log {
        // MARK: Type
        public enum `Type`: Int {
            case communication  = 0 // 通讯日志
            case running        = 1 // 运行日志
        }
        
        // MARK: var
        /// ID
        public var id: String = UUID().uuidString
        /// 类型
        public var type: `Type`
        /// 备注
        public var remark: String
    }
}
