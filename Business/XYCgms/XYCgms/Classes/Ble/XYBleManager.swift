//
//  XYBleManager.swift
//  XYCgms
//
//  Created by hsf on 2025/9/4.
//

// MARK: - Import
// System
import Foundation
import CoreBluetooth
// Basic
// Server
import XYCoreBluetooth
import XYLog
// Tool
// Business
// Third


// MARK: - XYBleManager
/// 蓝牙管理类（扫描）
public class XYBleManager: NSObject, XYCentralManagerWrapperDelegate {
    // MARK: log
    public static let logTag = "XY.Cgms.ble"
    
    // MARK: shared
    public static let shared = XYBleManager()
    private override init() {
        super.init()
        centralManagerWrapper = XYCentralManagerWrapper(delegate: self, queue: DispatchQueue(label: "com.hsf89757.XYCgms.ble", qos: .utility))
    }
    
    // MARK: var
    public private(set) var centralManagerWrapper: XYCentralManagerWrapper!
    /// 设备管理
    public private(set) var devices = [XYDevice]()
    /// 支持的CGMS设备
    public var supportedDeviceType: DeviceType = .wtdt
    
}


// MARK: - DeviceType
extension XYBleManager {
    public struct DeviceType: OptionSet {
        public let rawValue: Int
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        /// 微泰动态
        public static let wtdt: Self = .init(rawValue: 1 << 0)
        
        /// 服务UUID
        public var serviceUUIDs: [CBUUID]? {
            var uuids: [CBUUID]?
            if self.contains(.wtdt) {
                uuids?.append(XYWtdtManager.serviceUUID)
            }
            return uuids
        }
    }
}


// MARK: - Func
extension XYBleManager {
    public func startScan() {
        let logTag = [Self.logTag, "startScan"]
        XYLog.debug(tag: logTag)
        let serviceUUIDs = supportedDeviceType.serviceUUIDs
        let options: [String : Any] = [
           CBCentralManagerScanOptionSolicitedServiceUUIDsKey: serviceUUIDs,
           CBCentralManagerScanOptionAllowDuplicatesKey: true
        ]
        centralManagerWrapper.scanForPeripherals(withServices: serviceUUIDs, options: options)
    }
}


// MARK: - XYCentralManagerWrapperDelegate
extension XYBleManager {
    @available(iOS 7.0, *)
    public func centralManager(_ central: CBCentralManager, retrievePeripheralsWithIdentifiers identifiers: [UUID], returns peripherals: [CBPeripheral]) {
        
    }
    
    @available(iOS 7.0, *)
    public func centralManager(_ central: CBCentralManager, retrieveConnectedPeripheralsWithServices serviceUUIDs: [CBUUID], returns peripherals: [CBPeripheral]) {
        
    }

    public func centralManager(_ central: CBCentralManager, scanForPeripheralsWithServices serviceUUIDs: [CBUUID]?, options: [String: Any]?) {
        
    }
    
    public func centralManager(_ central: CBCentralManager, stopScan: Void) {
        
    }

    public func centralManager(_ central: CBCentralManager, connect peripheral: CBPeripheral, options: [String: Any]?) {
        
    }
    
    public func centralManager(_ central: CBCentralManager, cancelPeripheralConnection peripheral: CBPeripheral) {
       
    }

    @available(iOS 13.0, *)
    public func centralManager(_ central: CBCentralManager, registerForConnectionEventsWith options: [CBConnectionEventMatchingOption : Any]?) {
        
    }
}


// MARK: - CBCentralManagerDelegate
extension XYBleManager {
    
    @available(iOS 5.0, *)
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
    }
    
    @available(iOS 5.0, *)
    public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        
    }
    
    @available(iOS 5.0, *)
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
    }
    
    @available(iOS 5.0, *)
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
    }
    
    @available(iOS 5.0, *)
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
        
    }
    
    @available(iOS 5.0, *)
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
        
    }
    
    @available(iOS 5.0, *)
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, timestamp: CFAbsoluteTime, isReconnecting: Bool, error: (any Error)?) {
        
    }
    
    @available(iOS 13.0, *)
    public func centralManager(_ central: CBCentralManager, connectionEventDidOccur event: CBConnectionEvent, for peripheral: CBPeripheral) {
        
    }
    
    @available(iOS 13.0, *)
    public func centralManager(_ central: CBCentralManager, didUpdateANCSAuthorizationFor peripheral: CBPeripheral) {
        
    }
}


