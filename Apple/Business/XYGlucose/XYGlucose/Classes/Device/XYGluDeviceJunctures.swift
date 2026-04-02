//
//  XYGluDeviceJunctures.swift
//  XYCgms
//
//  Created by hsf on 2025/12/12.
//

import Foundation

// MARK: - XYGluDevice.Junctures
/// 设备生命关键节点
extension XYGluDevice {
    public class Junctures {
        /// 第一次配对成功时间
        public var pairedDate: Date?
        /// 激活成功时间
        public var activatedDate: Date?
        /// 预热完成时间
        public var preheatedDate: Date?
        /// 可校准时间
        public var calibratableDate: Date?
        /// 过期时间
        public var expiredDate: Date?
    }
}
