//
//  XYDeviceInfo.swift
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


// MARK: - XYDeviceInfo
/// 设备信息
public class XYDeviceInfo: Identifiable {
    // MARK: var
    /// 设备ID
    public var id: String = UUID().uuidString
    /// 设备名称
    public internal(set) var name: String?
    /// 设备序列号
    public internal(set) var sn: String?
    /// 设备型号
    public internal(set) var model: String?
    /// 设备批号
    public internal(set) var batchNumber: String?
    /// 设备固件版本号
    public internal(set) var firmwareVersion: String?
   
}
