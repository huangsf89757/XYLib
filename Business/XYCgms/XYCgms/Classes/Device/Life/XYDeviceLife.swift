//
//  XYDeviceStatus.swift
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


// MARK: - XYDeviceLife
/// 设备生命
public class XYDeviceLife {
    /// 设备生命阶段
    public var stage = XYDeviceStage.unpaired
    /// 设备生命进程
    public var process = XYDeviceProcess()
    /// 设备生命关键节点
    public var junctures = XYDeviceJunctures()
}

