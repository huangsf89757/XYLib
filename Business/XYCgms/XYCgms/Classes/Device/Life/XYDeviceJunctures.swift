//
//  XYDeviceJunctures.swift
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


// MARK: - XYDeviceJunctures
/// 设备生命关键节点
public class XYDeviceJunctures {
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
