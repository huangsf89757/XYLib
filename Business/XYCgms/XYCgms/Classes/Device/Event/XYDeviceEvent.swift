//
//  XYDeviceEvent.swift
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


// MARK: - XYDeviceEvent
/// 设备生命事件
public struct XYDeviceEvent: Identifiable {
    // MARK: EventResult
    public enum EventResult {
        case start
        case success
        case failure
    }
    // MARK: EventType
    public enum EventType {
        case pair
        case activate
        case preheatedNotify
        case calibratableNotify
        case calibrate
        case unpair
        case expiredNotify
    }
    
    // MARK: var
    /// 事件ID
    public var id: String = UUID().uuidString
    /// 事件类型
    public let type: EventType
    /// 事件结果
    public let result: EventResult
    /// 事件时间
    public let date: Date
    /// 事件信息
    public let info: String
}
