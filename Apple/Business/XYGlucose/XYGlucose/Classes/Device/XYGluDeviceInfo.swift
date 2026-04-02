//
//  XYGluDeviceInfo.swift
//  XYCgms
//
//  Created by hsf on 2025/12/12.
//

import Foundation

// MARK: - XYGluDevice.Info
/// 设备信息
extension XYGluDevice {
    public struct Info {
        /// ID
        public var id: String = UUID().uuidString
        /// 名称
        public internal(set) var name: String?
        /// 序列号
        public internal(set) var sn: String?
        /// 型号
        public internal(set) var model: String?
        /// 批号
        public internal(set) var batch: String?
        /// 固件版本号
        public internal(set) var firmwareVersion: String?
    }
}
