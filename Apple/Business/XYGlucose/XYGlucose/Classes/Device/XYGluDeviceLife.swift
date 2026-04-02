//
//  XYDeviceStatus.swift
//  XYCgms
//
//  Created by hsf on 2025/12/12.
//

import Foundation

// MARK: - XYGluDeviceLife
/// 设备生命
extension XYGluDevice {
    public class Life {
        /// 阶段
        public var stage = XYGluDevice.Stage.unpaired
        /// 进程
        public var process = XYGluDevice.Process()
        /// 关键节点
        public var junctures = XYGluDevice.Junctures()
    }
}

