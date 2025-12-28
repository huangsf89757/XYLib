//
//  XYWtdtCmd.swift
//  XYCgms
//
//  Created by hsf on 2025/12/18.
//

// MARK: - Import
// System
import Foundation
import CoreBluetooth
// Basic
import XYExtension
// Server
import XYCoreBluetooth
import XYLog
// Tool
// Business
// Third
import MTBleCore


// MARK: - XYWtdtCmd
/// 微泰动态CGMS蓝牙指令
public enum XYWtdtCmd {
    // MARK: 配对/解配
    /// 配对
    case pair
    /// 解配
    case unpair
    
    // MARK: 生命周期
    /// 生命开始（激活）
    case activate
    /// 清空数据
    case clear
    /// 生命重置
    case reset
        
    // MARK: 默认参数
    /// 设置默认参数
    case setDefaultParam
    /// 获取默认参数
    case getDefaultParam
    
    // MARK: 自动更新
    /// 设置自动更新状态
    case setAutoUpdateStatus
    /// 获取自动更新状态
    case getAutoUpdateStatus
    
    // MARK: 广播模式
    /// 设置广播模式
    case setDynamicAdvMode
    /// 获取广播模式
    case getDynamicAdvMode
    
    // MARK: 其他
    /// 获取广播数据
    case getBroadcast
    /// 获取设备信息
    case getDeviceInfo
    /// 获取开始时间
    case getStartTime
    
    // MARK: 血糖数据
    /// 获取数据范围
    case getHistoryRange
    /// 获取基础血糖记录数据
    case getBasicHistoryRecord
    /// 获取原始血糖记录数据
    case getRawHistoryRecord
    
    // MARK: 校准数据
    /// 校准
    case calibrate
    /// 获取校准范围
    case getCalibrationRange
    /// 获取校准记录数据
    case getCalibrationRecord
    
    // MARK: 设备日志数据
    /// 获取日志范围
    case getLogRange
    /// 获取日志数据
    case getLog
    /// 获取错误日志数据
    case getErrorLog
}

public extension XYWtdtCmd {
    
}
