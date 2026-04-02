//
//  XYGluDeviceProcess.swift
//  XYCgms
//
//  Created by hsf on 2025/12/12.
//

import Foundation

// MARK: - XYGluDeviceProcess
/// 设备生命进程
extension XYGluDevice {
    public struct Process {
        /// 最大进程
        public let end: Int = 21600
        /// 当前进程
        public var cur: Int = 0
    }
}

