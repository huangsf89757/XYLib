//
//  XYDevice.swift
//  XYCgms
//
//  Created by hsf on 2025/9/4.
//

// MARK: - Import
// System
import Foundation
import CoreBluetooth
// Basic
// Server
// Tool
// Business
// Third


// MARK: - XYDevice
/// 设备
public final class XYDevice {
    // MARK: var
    /// 设备信息
    public var info = XYDeviceInfo()
    /// 设备生命
    public var life = XYDeviceLife()
    /// 设备错误
    public var error: XYDeviceError? = nil
    /// 设备事件
    public var events = [XYDeviceEvent]()
    /// 设备日志
    public var log = XYDeviceLog()
}
