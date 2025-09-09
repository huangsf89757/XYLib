//
//  XYBleManager.swift
//  XYCgms
//
//  Created by hsf on 2025/8/26.
//

import Foundation
import CoreBluetooth
import XYExtension
import XYUtil
import XYLog

public final class XYBleManager: NSObject {
    // MARK: log
    public static let logTag = "BLE"
    
    // MARK: shared
    public static let shared = XYBleManager()
    private override init() {
        super.init()
        initCenterManager()
        addObservers()
    }
    deinit {
        removeObservers()
    }
    
    
    
    
    // MARK: var
    /// 持有的中央设备
    public internal(set) var centralManager: CBCentralManager!
    /// 广播日志
    public let discoverLogger = XYBleDiscoverLogger()
    /// 当前持有的外围设备
    public internal(set) var peripheral: CBPeripheral?
    /// 连接超时Task
    public internal(set) var connectTimeoutTask: DispatchWorkItem?
    
    
    
    internal var timer: Timer?
    
    
    /// 已发现的设备
    public internal(set) var discoveredDeviceList = [XYDeviceModel]()
    /// 已配对的设备
    public internal(set) var pairedDeviceList = [XYDeviceModel]()
    /// 未配对的设备
    public internal(set) var unpairedDeviceList = [XYDeviceModel]()
    /// 当前连接的设备
    public var connectedDevice: XYDeviceModel?
    
    
}


