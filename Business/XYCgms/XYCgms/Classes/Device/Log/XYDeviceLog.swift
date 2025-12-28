//
//  XYDeviceLog.swift
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


// MARK: - XYDeviceLog
/// 设备日志
public class XYDeviceLog : Identifiable {
    // MARK: LogType
    public enum LogType {
        case communication
        case running
    }
    
    // MARK: var
    /// 日志ID
    public var id: String = UUID().uuidString
}
