//
//  XYBleCentralManager.swift
//  XYCgms
//
//  Created by hsf on 2025/8/28.
//

import Foundation
import CoreBluetooth
import XYExtension
import XYUtil
import XYLog

extension XYBleManager {
    /// 恢复Key
    public static let restoreKey = XYApp.bundleId + "_" + "KEY_BLE_RESTORE"
    /// 扫描服务UUID
    public static var scanServiceUuids = ["181F"].map { CBUUID(string: $0) }
    /// 连接外设超时时间
    public static var connectTimeout: TimeInterval = 30
}

extension XYBleManager {
    /// 初始化
    internal func initCenterManager() {
        let logTag = [Self.logTag, "initCenterManager()"]
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [
            CBCentralManagerOptionShowPowerAlertKey: true,
            CBCentralManagerOptionRestoreIdentifierKey: Self.restoreKey,
        ])
        XYLog.info(tag: logTag, process: .succ)
    }
}

extension XYBleManager {
    /// 开启扫描
    public func statrScan() {
        let logTag = [Self.logTag, "statrScan()"]
        let options = [
           CBCentralManagerScanOptionAllowDuplicatesKey: true
        ]
        XYLog.info(tag: logTag, process: .begin, content: "options=\(options.toJSONString() ?? "nil")")
        guard centralManager.state == .poweredOn else {
            XYLog.info(tag: logTag, process: .fail("central.state=\(centralManager.state.info)"))
            return
        }
        centralManager.scanForPeripherals(withServices: Self.scanServiceUuids, options: options)
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

extension XYBleManager {
    /// 连接外设
    public func connect(uuid: String) {
        let logTag = [Self.logTag, "connectPeripheral()"]
        var options = [
            CBConnectPeripheralOptionNotifyOnConnectionKey: true,
            CBConnectPeripheralOptionNotifyOnDisconnectionKey: true,
            CBConnectPeripheralOptionNotifyOnNotificationKey: true
        ]
//        if #available(watchOS 10.0, *) {
//            if #available(iOS 17.0, *) {
//                options[CBConnectPeripheralOptionEnableAutoReconnect] = true
//            } else {
//                // Fallback on earlier versions
//            }
//        }
        XYLog.info(tag: logTag, process: .begin, content: "options=\(options.toJSONString() ?? "nil")")
        guard centralManager.state == .poweredOn else {
            XYLog.info(tag: logTag, process: .fail("central.state=\(centralManager.state.info)"))
            return
        }
        guard let UUID = UUID(uuidString: uuid) else {
            XYLog.info(tag: logTag, process: .fail("UUID=nil"))
            return
        }
        let peripherals = centralManager.retrievePeripherals(withIdentifiers: [UUID])
        guard let peripheral = peripherals.first else {
            XYLog.info(tag: logTag, process: .fail("peripheral=nil"))
            return
        }
        self.peripheral = peripheral // 必须持有
        
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
            XYLog.info(tag: logTag, process: .fail("UNKNOWN ERROR"))
            return
        }
        
        // 超时任务
        let task = DispatchWorkItem {
            XYLog.info(tag: logTag, process: .fail("UNKNOWN ERROR"))
            self.disconnectPeripheral()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.connectTimeout, execute: task)
        connectTimeoutTask = task
        
        // 连接
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
        guard let peripheral = peripheral else {
            XYLog.info(tag: logTag, process: .fail("peripheral=nil"))
            return
        }
        centralManager.cancelPeripheralConnection(peripheral)
    }
}


// MARK: - CBCentralManagerDelegate
extension XYBleManager: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let logTag = [Self.logTag, "didUpdateState()"]
        let state = central.state
        XYLog.info(tag: logTag, content: "central.state=\(state.info)")
        if state == .poweredOn {
            statrScan()
        }
    }
    
    public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        let logTag = [Self.logTag, "didUpdateState()"]
        XYLog.info(tag: logTag, content: "dict=\(dict)")
    }

    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let logTag = [Self.logTag, "didDiscoverPeripheral()"]
        discoverLogger.log(tag: logTag, peripheral: peripheral, advertisementData: advertisementData, rssi: RSSI)
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        let logTag = [Self.logTag, "didConnectPeripheral()"]
        XYLog.info(tag: logTag, content: "peripheral=\(peripheral.info)")
        connectTimeoutTask?.cancel()
    }

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        let logTag = [Self.logTag, "didFailToConnectPeripheral()"]
        if let error = error {
            XYLog.info(tag: logTag, content: "peripheral=\(peripheral.info)", "error=\(error.localizedDescription)")
        } else {
            XYLog.info(tag: logTag, content: "peripheral=\(peripheral.info)")
        }
        self.peripheral = nil
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        let logTag = [Self.logTag, "didDisconnectPeripheral()"]
        if let error = error {
            XYLog.info(tag: logTag, content: "peripheral=\(peripheral.info)", "error=\(error.localizedDescription)")
        } else {
            XYLog.info(tag: logTag, content: "peripheral=\(peripheral.info)")
        }
        self.peripheral = nil
    }
}
