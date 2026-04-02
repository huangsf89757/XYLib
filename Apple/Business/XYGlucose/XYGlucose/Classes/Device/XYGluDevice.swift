//
//  XYGluDevice.swift
//  XYCgms
//
//  Created by hsf on 2025/9/4.
//

import Foundation
import CoreBluetooth

// MARK: - XYGluDevice
/// 血糖设备
public class XYGluDevice {
    // MARK: var
    /// 信息
    public var info = XYGluDevice.Info()
    /// 生命
    public var life = XYGluDevice.Life()
    /// 错误
    public var error: XYGluDevice.Error?
    /// 事件
    public var events = [XYGluDevice.Event]()
    /// 日志
    public var logs = [XYGluDevice.Log]()
    /// 当前血糖数据
    public var data: XYGluData?
}
