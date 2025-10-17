//
//  XYCentralManager.swift
//  XYCoreBluetooth
//
//  Created by hsf on 2025/10/14.
//

// Module: System
import Foundation
import CoreBluetooth
// Module: Basic
import XYExtension
// Module: Server
import XYLog
// Module: Tool
import XYUtil
// Module: Business
// Module: Third

// MARK: - XYCentralManager
/// 蓝牙中心管理器类，封装了CBCentralManager的功能，提供蓝牙设备扫描、连接等操作
open class XYCentralManager: NSObject {
    // MARK: Property
    /// CBCentralManager实例，用于管理蓝牙中心设备
    public private(set) var centralManager: CBCentralManager!
    /// 代理对象，用于处理蓝牙事件回调
    public weak var delegate: (any XYCentralManagerDelegate)?
    
    /// 授权状态
    @available(iOS 13.1, *)
    open class var authorization: CBManagerAuthorization {
        return CBPeripheralManager.authorization
    }
    
    /// 蓝牙状态
    open var state: CBManagerState {
        return centralManager.state
    }
    
    /// 当前是否正在扫描蓝牙设备（iOS 9.0+）
    @available(iOS 9.0, *)
    public var isScanning: Bool {
        return centralManager.isScanning
    }
    
    // MARK: Life Cycle
    /// 初始化蓝牙中心管理器
    /// - Parameters:
    ///   - delegate: 代理对象，用于处理蓝牙事件回调
    ///   - queue: 调度队列，默认为nil（主队列）
    ///   - options: 初始化选项，默认为nil
    public init(delegate: (any XYCentralManagerDelegate)?, queue: dispatch_queue_t? = nil, options: [String : Any]? = nil) {
        super.init()
        centralManager = CBCentralManager(delegate: delegate, queue: queue, options: options)
        centralManager.delegate = self
        
        self.delegate = delegate
        XYBleLog.debug(params:[
            "delegate": delegate?.description ?? "nil",
            "queue": queue?.description ?? "nil",
            "options": options?.toJSONString() ?? "nil",
        ])
    }
    
    // MARK: Retrieve
    /// 根据标识符检索已知的蓝牙外设
    /// - Parameter identifiers: 外设标识符数组
    /// - Returns: 匹配的外设数组
    @available(iOS 7.0, *)
    open func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [CBPeripheral] {
        let peripherals = centralManager.retrievePeripherals(withIdentifiers: identifiers)
        XYBleLog.debug(params:[
            "identifiers": identifiers.map{ $0.uuidString }.toJSONString() ?? "[]",
        ], returns: peripherals.map{ $0.info }.toJSONString())
        self.delegate?.centralManager(centralManager, retrievePeripheralsWithIdentifiers: identifiers, returns: peripherals)
        return peripherals
    }

    /// 检索已连接的蓝牙外设
    /// - Parameter serviceUUIDs: 服务UUID数组
    /// - Returns: 匹配的外设数组
    @available(iOS 7.0, *)
    open func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> [CBPeripheral] {
        let peripherals = centralManager.retrieveConnectedPeripherals(withServices: serviceUUIDs)
        XYBleLog.debug(params:[
            "serviceUUIDs": serviceUUIDs.map{ $0.uuidString }.toJSONString() ?? "[]",
        ], returns: peripherals.map{ $0.info }.toJSONString())
        self.delegate?.centralManager(centralManager, retrieveConnectedPeripheralsWithServices: serviceUUIDs, returns: peripherals)
        return peripherals
    }
    
    // MARK: Scan
    /// 开始扫描蓝牙外设
    /// - Parameters:
    ///   - serviceUUIDs: 要扫描的服务UUID数组，为nil时扫描所有设备
    ///   - options: 扫描选项，默认为nil
    open func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String : Any]? = nil) {
        centralManager.scanForPeripherals(withServices: serviceUUIDs, options: options)
        XYBleLog.debug(params:[
            "serviceUUIDs": serviceUUIDs?.map{ $0.uuidString }.toJSONString() ?? "nil",
            "options": options?.toJSONString() ?? "nil",
        ])
        self.delegate?.centralManager(centralManager, scanForPeripheralsWithServices: serviceUUIDs, options: options)
    }
    
    /// 停止扫描蓝牙外设
    open func stopScan() {
        centralManager.stopScan()
        XYBleLog.debug()
        self.delegate?.centralManager(centralManager, stopScan: ())
    }
    
    // MARK: Connect
    /// 连接指定的蓝牙外设
    /// - Parameters:
    ///   - peripheral: 要连接的外设
    ///   - options: 连接选项，默认为nil
    open func connect(_ peripheral: CBPeripheral, options: [String : Any]? = nil) {
        centralManager.connect(peripheral, options: options)
        XYBleLog.debug(params:[
            "peripheral": peripheral.info,
            "options": options?.toJSONString() ?? "nil",
        ])
        self.delegate?.centralManager(centralManager, connect: peripheral, options: options)
    }
    
    /// 取消与指定蓝牙外设的连接
    /// - Parameter peripheral: 要断开连接的外设
    open func cancelPeripheralConnection(_ peripheral: CBPeripheral) {
        centralManager.cancelPeripheralConnection(peripheral)
        XYBleLog.debug(params:[
            "peripheral": peripheral.info,
        ])
        self.delegate?.centralManager(centralManager, cancelPeripheralConnection: peripheral)
    }

    // MARK: Event
    /// 注册连接事件（iOS 13.0+）
    /// - Parameter options: 连接事件匹配选项，默认为nil
    @available(iOS 13.0, *)
    open func registerForConnectionEvents(options: [CBConnectionEventMatchingOption : Any]? = nil) {
        centralManager.registerForConnectionEvents(options: options)
        XYBleLog.debug(params:[
            "options": options?.toJSONString() ?? "nil",
        ])
        self.delegate?.centralManager(centralManager, registerForConnectionEventsWithOptions: options)
    }
}

// MARK: - CBCentralManagerDelegate
extension XYCentralManager: CBCentralManagerDelegate {
    
    /// 中心管理器状态更新回调
    /// - Parameter central: 中心管理器实例
    @available(iOS 5.0, *)
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        self.delegate?.centralManagerDidUpdateState(central)
        XYBleLog.debug(params:[
            "centralManager": central.info,
        ])
    }

    /// 中心管理器状态恢复回调
    /// - Parameters:
    ///   - central: 中心管理器实例
    ///   - dict: 状态字典
    @available(iOS 5.0, *)
    public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        self.delegate?.centralManager?(central, willRestoreState: dict)
        XYBleLog.debug(params:[
            "centralManager": central.info,
            "dict": dict.toJSONString() ?? "[:]",
        ])
    }

    /// 发现外设回调
    /// - Parameters:
    ///   - central: 中心管理器实例
    ///   - peripheral: 发现的外设
    ///   - advertisementData: 广播数据
    ///   - RSSI: 信号强度
    @available(iOS 5.0, *)
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        self.delegate?.centralManager?(central, didDiscover: peripheral, advertisementData: advertisementData, rssi: RSSI)
        XYBleLog.debug(params:[
            "centralManager": central.info,
            "peripheral": peripheral.info,
            "advertisementData": advertisementData.toJSONString() ?? "[:]",
            "RSSI": RSSI.stringValue,
        ])
    }

    /// 连接外设成功回调
    /// - Parameters:
    ///   - central: 中心管理器实例
    ///   - peripheral: 连接成功的外设
    @available(iOS 5.0, *)
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.delegate?.centralManager?(central, didConnect: peripheral)
        XYBleLog.debug(params:[
            "centralManager": central.info,
            "peripheral": peripheral.info,
        ])
    }

    /// 连接外设失败回调
    /// - Parameters:
    ///   - central: 中心管理器实例
    ///   - peripheral: 连接失败的外设
    ///   - error: 错误信息
    @available(iOS 5.0, *)
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
        self.delegate?.centralManager?(central, didFailToConnect: peripheral, error: error)
        XYBleLog.debug(params:[
            "centralManager": central.info,
            "peripheral": peripheral.info,
            "error": error?.localizedDescription ?? "nil",
        ])
    }
    
    /// 断开外设连接回调
    /// - Parameters:
    ///   - central: 中心管理器实例
    ///   - peripheral: 断开连接的外设
    ///   - error: 错误信息，为nil表示正常断开
    @available(iOS 5.0, *)
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
        self.delegate?.centralManager?(central, didDisconnectPeripheral: peripheral, error: error)
        XYBleLog.debug(params:[
            "centralManager": central.info,
            "peripheral": peripheral.info,
            "error": error?.localizedDescription ?? "nil",
        ])
    }

    /// 断开外设连接回调（带时间戳和重连状态）
    /// - Parameters:
    ///   - central: 中心管理器实例
    ///   - peripheral: 断开连接的外设
    ///   - timestamp: 断开连接的时间戳
    ///   - isReconnecting: 是否正在重连
    ///   - error: 错误信息，为nil表示正常断开
    @available(iOS 5.0, *)
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, timestamp: CFAbsoluteTime, isReconnecting: Bool, error: (any Error)?) {
        self.delegate?.centralManager?(central, didDisconnectPeripheral: peripheral, timestamp: timestamp, isReconnecting: isReconnecting, error: error)
        XYBleLog.debug(params:[
            "centralManager": central.info,
            "peripheral": peripheral.info,
            "timestamp": String(format: "%.2f", timestamp),
            "isReconnecting": String(isReconnecting),
            "error": error?.localizedDescription ?? "nil",
        ])
    }

    /// 连接事件发生回调（iOS 13.0+）
    /// - Parameters:
    ///   - central: 中心管理器实例
    ///   - event: 连接事件类型
    ///   - peripheral: 相关外设
    @available(iOS 13.0, *)
    public func centralManager(_ central: CBCentralManager, connectionEventDidOccur event: CBConnectionEvent, for peripheral: CBPeripheral) {
        self.delegate?.centralManager?(central, connectionEventDidOccur: event, for: peripheral)
        XYBleLog.debug(params:[
            "centralManager": central.info,
            "event": String(describing: event),
            "peripheral": peripheral.info,
        ])
    }

    /// ANCS授权更新回调（iOS 13.0+）
    /// - Parameters:
    ///   - central: 中心管理器实例
    ///   - peripheral: 相关外设
    @available(iOS 13.0, *)
    public func centralManager(_ central: CBCentralManager, didUpdateANCSAuthorizationFor peripheral: CBPeripheral) {
        self.delegate?.centralManager?(central, didUpdateANCSAuthorizationFor: peripheral)
        XYBleLog.debug(params:[
            "centralManager": central.info,
            "peripheral": peripheral.info,
        ])
    }
}

