//
//  XYCentralManager.swift
//  Pods
//
//  Created by hsf on 2025/9/10.
//

import Foundation
import CoreBluetooth
import XYExtension
import XYUtil
import XYLog

public final class XYCentralManager: NSObject {
    // MARK: log
    public static let logTag = "Ble.CM"
    
    // MARK: shared
    public static let shared = XYCentralManager()
    private override init() {
        super.init()
        initCenterManager()
        addObservers()
    }
    private func initCenterManager() {
        let logTag = [Self.logTag, "initCenterManager()"]
        let options: [String : Any] = [
            CBCentralManagerOptionShowPowerAlertKey: true,
            CBCentralManagerOptionRestoreIdentifierKey: Self.restoreKey,
        ]
        centralManager = CBCentralManager(delegate: self, queue: nil, options: options)
        XYLog.info(tag: logTag, process: .succ, content: "options=\(options.toJSONString() ?? "nil")")
    }
    deinit {
        removeObservers()
    }
    
    // MARK: ble
    /// 恢复Key
    public static let restoreKey = XYApp.key + "." + "BLE.RESTORE"
    /// 连接外设超时时间
    public static var connectTimeout: TimeInterval = 30
    
    
    // MARK: centralManager
    /// 持有的中央设备
    public internal(set) var centralManager: CBCentralManager!
    /// 广播日志
    public let discoverLogger = XYDiscoverLogger()
    /// 连接超时Task
    public internal(set) var connectTimeoutTask: DispatchWorkItem?
    
    
    // MARK: peripheral
    public internal(set) var xyPeripheral: XYPeripheral?
    
    
    // MARK: plugin
    public var plugins = [XYCentralManagerPlugin]()
    
}

// MARK: - CBCentralManagerDelegate
extension XYCentralManager: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let logTag = [Self.logTag, "didUpdateState()"]
        let state = central.state
        XYLog.info(tag: logTag, content: "central.state=\(state.info)")
        plugins.forEach { plugin in
            plugin.centralManagerDidUpdateState(central)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        let logTag = [Self.logTag, "willRestoreState()"]
        XYLog.info(tag: logTag, content: "dict=\(dict)")
        plugins.forEach { plugin in
            plugin.centralManager?(central, willRestoreState: dict)
        }
    }
}

// MARK: - scan
extension XYCentralManager {
    /// 开启扫描
    public func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String : Any]? = nil) {
        let logTag = [Self.logTag, "statrScan()"]
        if let options = options {
            XYLog.info(tag: logTag, process: .begin, content: "options=\(options.toJSONString() ?? "nil")")
        } else {
            XYLog.info(tag: logTag, process: .begin)
        }
        guard centralManager.state == .poweredOn else {
            XYLog.info(tag: logTag, process: .fail("central.state=\(centralManager.state.info)"))
            return
        }
        centralManager.scanForPeripherals(withServices: serviceUUIDs, options: options)
    }
    
    /// 停止扫描
    public func stopScan() {
        let logTag = [Self.logTag, "stopScan()"]
        XYLog.info(tag: logTag, process: .begin)
        guard centralManager.state == .poweredOn else {
            XYLog.info(tag: logTag, process: .fail("central.state=\(centralManager.state.info)"))
            return
        }
        centralManager.stopScan()
    }    
}

extension XYCentralManager {
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let logTag = [Self.logTag, "didDiscoverPeripheral()"]
        discoverLogger.log(tag: logTag, peripheral: peripheral, advertisementData: advertisementData, rssi: RSSI)
        plugins.forEach { plugin in
            plugin.centralManager?(central, didDiscover: peripheral, advertisementData: advertisementData, rssi: RSSI)
        }
    }
}

// MARK: - connect
extension XYCentralManager {
    /// 连接外设
    public func connect(_ peripheral: CBPeripheral, options: [String : Any]? = nil) {
        let logTag = [Self.logTag, "connectPeripheral()"]
        if let options = options {
            XYLog.info(tag: logTag, process: .begin, content: "options=\(options.toJSONString() ?? "nil")")
        } else {
            XYLog.info(tag: logTag, process: .begin)
        }
        guard centralManager.state == .poweredOn else {
            XYLog.info(tag: logTag, process: .fail("central.state=\(centralManager.state.info)"))
            return
        }
        
        // 连接前判断状态
        switch peripheral.state {
        case .disconnected:
            break
        case .connecting:
            XYLog.info(tag: logTag, process: .doing, content: "this peripheral is connecting")
            return
        case .connected:
            XYLog.info(tag: logTag, process: .succ, content: "this peripheral is already connected")
            return
        case .disconnecting:
            XYLog.info(tag: logTag, process: .fail("this peripheral is disconnecting"))
            return
        @unknown default:
            XYLog.info(tag: logTag, process: .fail("@unknown ERROR"))
            return
        }
        
        // 超时任务
        connectTimeoutTask?.cancel()
        let task = DispatchWorkItem {
            XYLog.info(tag: logTag, process: .fail("TIMEOUT"))
            self.disconnectPeripheral()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.connectTimeout, execute: task)
        connectTimeoutTask = task
        
        // 连接
        self.xyPeripheral = XYPeripheral(peripheral: peripheral)
        centralManager.connect(peripheral, options: options)
    }
    
    /// 断开已连接的外设
    public func disconnectPeripheral() {
        let logTag = [Self.logTag, "disconnectPeripheral()"]
        XYLog.info(tag: logTag, process: .begin)
        guard centralManager.state == .poweredOn else {
            XYLog.info(tag: logTag, process: .fail("central.state=\(centralManager.state.info)"))
            return
        }
        guard let xyPeripheral = xyPeripheral else {
            XYLog.info(tag: logTag, process: .fail("peripheral=nil"))
            return
        }
        centralManager.cancelPeripheralConnection(xyPeripheral.peripheral)
    }
}

extension XYCentralManager {
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        let logTag = [Self.logTag, "didConnectPeripheral()"]
        XYLog.info(tag: logTag, content: "peripheral=\(peripheral.info)")
        connectTimeoutTask?.cancel()
        plugins.forEach { plugin in
            plugin.centralManager?(central, didConnect: peripheral)
        }
    }

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        let logTag = [Self.logTag, "didFailToConnectPeripheral()"]
        if let error = error {
            XYLog.info(tag: logTag, content: "peripheral=\(peripheral.info)", "error=\(error.localizedDescription)")
        } else {
            XYLog.info(tag: logTag, content: "peripheral=\(peripheral.info)")
        }
        self.xyPeripheral = nil
        connectTimeoutTask?.cancel()
        plugins.forEach { plugin in
            plugin.centralManager?(central, didFailToConnect: peripheral, error: error)
        }
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        let logTag = [Self.logTag, "didDisconnectPeripheral()"]
        if let error = error {
            XYLog.info(tag: logTag, content: "peripheral=\(peripheral.info)", "error=\(error.localizedDescription)")
        } else {
            XYLog.info(tag: logTag, content: "peripheral=\(peripheral.info)")
        }
        self.xyPeripheral = nil
        connectTimeoutTask?.cancel()
        plugins.forEach { plugin in
            plugin.centralManager?(central, didDisconnectPeripheral: peripheral, error: error)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, timestamp: CFAbsoluteTime, isReconnecting: Bool, error: (any Error)?) {
        let logTag = [Self.logTag, "didDisconnectPeripheralWithReconnect()"]
        if let error = error {
            XYLog.info(tag: logTag, content: "peripheral=\(peripheral.info)", "timestamp=\(timestamp)", "isReconnecting=\(isReconnecting)", "error=\(error.localizedDescription)")
        } else {
            XYLog.info(tag: logTag, content: "peripheral=\(peripheral.info)", "timestamp=\(timestamp)", "isReconnecting=\(isReconnecting)")
        }
        self.xyPeripheral = nil
        connectTimeoutTask?.cancel()
        plugins.forEach { plugin in
            plugin.centralManager?(central, didDisconnectPeripheral: peripheral, timestamp: timestamp, isReconnecting: isReconnecting, error: error)
        }
    }
}

// MARK: - KVO
extension XYCentralManager {
    private func addObservers() {
        centralManager.addObserver(self, forKeyPath: "isScanning", options: .new, context: nil)
    }
    
    private func removeObservers() {
        centralManager.removeObserver(self, forKeyPath: "isScanning")
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        let logTag = [Self.logTag, "KVO"]
        if let centralManager = object as? CBCentralManager, centralManager == self.centralManager {
            if keyPath == "isScanning", let isScanning = change?[.newKey] as? Bool {
                XYLog.info(tag: logTag, content: "central.isScanning=\(isScanning)")
                return
            }
            return
        }
    }
}
