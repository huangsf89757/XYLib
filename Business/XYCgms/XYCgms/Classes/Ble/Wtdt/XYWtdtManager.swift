//
//  XYWtdtManager.swift
//  XYCgms
//
//  Created by hsf on 2025/9/4.
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


// MARK: - XYWtdtManager
/// 蓝牙管理类（微泰动态）
public class XYWtdtManager: NSObject {
    // MARK: log
    public static let logTag = "XY.Cgms.Wtdt"
    
    // MARK: uuid
    public static let serviceUUID = CBUUID(string: "181F")
    public static let characteristicUUIDs: [String: CBUUID] = [
        "F001", "F002", "F003", "F005"
    ].reduce(into: [:]) { dict, uuid in
        dict[uuid] = CBUUID(string: uuid)
    }
    
    // MARK: shared
    public static let shared = XYWtdtManager()
    private override init() {
        super.init()
        centralManagerWrapper = XYCentralManagerWrapper(delegate: self, queue: DispatchQueue(label: "com.hsf89757.XYCgms.wtdt", qos: .utility))
    }
    
    // MARK: var
    public private(set) var centralManagerWrapper: XYCentralManagerWrapper!
    public private(set) var peripheralWrapper: XYPeripheralWrapper?
    
    public private(set) var action: XYWtdtAction?
    
}

// MARK: - MTBleAdapter
extension XYWtdtManager {
    func adapt() {
    // MARK: CentralManager
        MTBleAdapter.shared().startScanBlock = {
            [weak self] in
            let logTag = [Self.logTag, "startScanBlock"]
            XYLog.debug(tag: logTag)
            let serviceUUIDs = [Self.serviceUUID]
            let options: [String : Any] = [
               CBCentralManagerScanOptionSolicitedServiceUUIDsKey: serviceUUIDs,
               CBCentralManagerScanOptionAllowDuplicatesKey: true
            ]
            self?.centralManagerWrapper.scanForPeripherals(withServices: serviceUUIDs, options: options)
        }
        MTBleAdapter.shared().stopScanBlock = {
            [weak self] in
            let logTag = [Self.logTag, "stopScanBlock"]
            XYLog.info(tag: logTag)
            self?.centralManagerWrapper.stopScan()
        }
        MTBleAdapter.shared().readyToConnectBlock = {
            [weak self] uuidString in
            let logTag = [Self.logTag, "readyToConnectBlock"]
            XYLog.info(tag: logTag, process: .begin, content: "uuidString=\(uuidString)")
            guard let uuid = UUID(uuidString: uuidString) else {
                XYLog.info(tag: logTag, process: .fail, content: "uuid=nil")
                return false
            }
            let peripherals = self?.centralManagerWrapper.retrievePeripherals(withIdentifiers: [uuid]) ?? []
            return peripherals.count > 0
        }
        MTBleAdapter.shared().connectBlock = {
            [weak self] uuidString in
            let logTag = [Self.logTag, "connectBlock"]
            XYLog.info(tag: logTag, process: .begin, content: "uuidString=\(uuidString)")
            guard let uuid = UUID(uuidString: uuidString) else {
                XYLog.info(tag: logTag, process: .fail, content: "uuid=nil")
                MTBleAdapter.shared().onConnectFailure()
                return
            }
            let peripherals = self?.centralManagerWrapper.retrievePeripherals(withIdentifiers: [uuid]) ?? []
            guard let peripheral = peripherals.first else {
                XYLog.info(tag: logTag, process: .fail, content: "retrievePeripheral=nil")
                MTBleAdapter.shared().onConnectFailure()
                return
            }
            var options = [
                CBConnectPeripheralOptionNotifyOnConnectionKey: true,
                CBConnectPeripheralOptionNotifyOnDisconnectionKey: true,
                CBConnectPeripheralOptionNotifyOnNotificationKey: true,
            ]
            if #available(iOS 17.0, watchOS 10.0, *) {
                options[CBConnectPeripheralOptionEnableAutoReconnect] = true
            }
            self?.centralManagerWrapper.connect(peripheral, options: options)
            self?.peripheralWrapper = XYPeripheralWrapper(peripheral: peripheral, delegate: self)
        }
        MTBleAdapter.shared().disconnectBlock = {
            [weak self] in
            let logTag = [Self.logTag, "disconnectBlock"]
            guard let peripheralWrapper = self?.peripheralWrapper else {
                XYLog.info(tag: logTag, process: .fail, content: "peripheralWrapper=nil")
                return
            }
            guard let peripheral = peripheralWrapper.peripheral else {
                XYLog.info(tag: logTag, process: .fail, content: "peripheral=nil")
                return
            }
            self?.centralManagerWrapper.cancelPeripheralConnection(peripheral)
        }
    // MARK: Peripheral
        MTBleAdapter.shared().writeBlock = {
            [weak self] data, uuidString in
            let logTag = [Self.logTag, "writeBlock"]
            XYLog.info(tag: logTag, process: .begin, content: "uuidString=\(uuidString)", "data=\(data.toHexString())")
            guard let uuidString = uuidString else {
                XYLog.info(tag: logTag, process: .fail, content: "uuid=nil")
                return
            }
            guard let peripheralWrapper = self?.peripheralWrapper else {
                XYLog.info(tag: logTag, process: .fail, content: "peripheralWrapper=nil")
                return
            }
            let characteristic = peripheralWrapper.getCharacteristic(uuidString: uuidString)
            guard let characteristic = characteristic else {
                XYLog.info(tag: logTag, process: .fail, content: "characteristic=nil")
                return
            }
            var type: CBCharacteristicWriteType?
            if characteristic.properties.contains(.write) {
                type = .withResponse
            }
            else if characteristic.properties.contains(.writeWithoutResponse) {
                type = .withoutResponse
            }
            guard let type = type else {
                XYLog.info(tag: logTag, process: .fail, content: "type=nil")
                return
            }
            peripheralWrapper.writeValue(data, for: characteristic, type: type)
        }
        MTBleAdapter.shared().readBlock = {
            [weak self] uuidString in
            let logTag = [Self.logTag, "readBlock"]
            XYLog.info(tag: logTag, process: .begin, content: "uuidString=\(uuidString)")
            guard let uuidString = uuidString else {
                XYLog.info(tag: logTag, process: .fail, content: "uuid=nil")
                return
            }
            guard let peripheralWrapper = self?.peripheralWrapper else {
                XYLog.info(tag: logTag, process: .fail, content: "peripheralWrapper=nil")
                return
            }
            let characteristic = peripheralWrapper.getCharacteristic(uuidString: uuidString)
            guard let characteristic = characteristic else {
                XYLog.info(tag: logTag, process: .fail, content: "characteristic=nil")
                return
            }
            peripheralWrapper.readValue(for: characteristic)
        }
        MTBleAdapter.shared().enableBlock = {
            [weak self] uuidString in
            let logTag = [Self.logTag, "enableBlock"]
            XYLog.info(tag: logTag, process: .begin, content: "uuidString=\(uuidString)")
            guard let uuidString = uuidString else {
                XYLog.info(tag: logTag, process: .fail, content: "uuid=nil")
                return
            }
            guard let peripheralWrapper = self?.peripheralWrapper else {
                XYLog.info(tag: logTag, process: .fail, content: "xyperipheral=nil")
                return
            }
            let characteristic = peripheralWrapper.getCharacteristic(uuidString: uuidString)
            guard let characteristic = characteristic else {
                XYLog.info(tag: logTag, process: .fail, content: "characteristic=nil")
                return
            }
            peripheralWrapper.setNotifyValue(true, for: characteristic)
        }
        MTBleAdapter.shared().advertisementBlock = {
            [weak self] controller in
            let logTag = [Self.logTag, "advertisementBlock"]
            XYLog.info(tag: logTag)
        }
        MTBleAdapter.shared().messageBlock = {
            [weak self] controller, message in
            let logTag = [Self.logTag, "messageBlock"]
            XYLog.info(tag: logTag)
            
            
            
        }
    }
}


// MARK: - XYCentralManagerWrapperDelegate
extension XYWtdtManager: XYCentralManagerWrapperDelegate {
    
    @available(iOS 5.0, *)
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard central.state == .poweredOn else { return }
        disconnectSuccess()
    }
    
    @available(iOS 5.0, *)
    public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        guard let restoredPeripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] else {
            return
        }
    }
    
    @available(iOS 5.0, *)
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        MTBleAdapter.shared().onAppleDidDiscoverPeripheral(peripheral.identifier.uuidString, advertisementData: advertisementData, rssi: RSSI)
    }
    
    @available(iOS 5.0, *)
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard let xyperipheral = validate(peripheral) else {
            return
        }
        connectSuccess()
        let serviceUUIDs = [Self.serviceUUID]
        xyperipheral.discoverServices(serviceUUIDs)
    }
    
    @available(iOS 5.0, *)
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
        guard let xyperipheral = validate(peripheral) else {
            return
        }
        disconnectSuccess()
    }
    
    @available(iOS 5.0, *)
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
        guard let xyperipheral = validate(peripheral) else {
            return
        }
        disconnectSuccess()
    }    
}


// MARK: - XYPeripheralWrapperDelegate
extension XYWtdtManager: XYPeripheralWrapperDelegate {
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        guard let xyperipheral = validate(peripheral, error: error) else {
            return
        }
        let services = peripheral.services ?? []
        for service in services {
            let characteristicUUIDs = Array(Self.characteristicUUIDs.values)
            xyperipheral.discoverCharacteristics(characteristicUUIDs, for: service)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
        guard let xyperipheral = validate(peripheral, error: error) else {
            return
        }
        let characteristics = service.characteristics ?? []
        for characteristic in characteristics {
            if characteristic.properties.contains(.notify) {
                xyperipheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: (any Error)?) {
        guard let xyperipheral = validate(peripheral, error: error) else {
            return
        }
        MTBleAdapter.shared().onCharacteristicNotifyEnable(characteristic.uuid.uuidString)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        guard let xyperipheral = validate(peripheral, error: error) else {
            return
        }
        guard let value = characteristic.value else {
            if characteristic.uuid == Self.characteristicUUIDs["F005"] {
                disconnect(peripheral)
            }
            return
        }
        MTBleAdapter.shared().onReceiveValue(value, forCharacteristicUUid: characteristic.uuid.uuidString)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        guard let xyperipheral = validate(peripheral, error: error) else {
            return
        }
    }
}


// MARK: - Func
extension XYWtdtManager {
    
    private func validate(_ peripheral: CBPeripheral, error: (any Error)? = nil) -> XYPeripheralWrapper? {
        let identifier = peripheral.identifier
        guard let peripheralWrapper = self.peripheralWrapper,
              peripheralWrapper.peripheral.identifier == identifier else {
            return nil
        }
        if let error = error {
            disconnect(peripheral)
            return nil
        }
        return peripheralWrapper
    }
    
    private func disconnect(_ peripheral: CBPeripheral) {
        centralManagerWrapper.cancelPeripheralConnection(peripheral)
        disconnectSuccess()
    }
    
    private func connectSuccess() {
        MTBleAdapter.shared().onConnectSuccess()
    }
    
    private func disconnectSuccess() {
        MTBleAdapter.shared().onDisconnected()
        self.peripheralWrapper = nil
    }
}
