//
//  XYPeripheralAgent.swift
//  Pods
//
//  Created by hsf on 2025/9/10.
//

import Foundation
import CoreBluetooth
import XYExtension
import XYUtil
import XYLog

public final class XYPeripheralAgent: NSObject {
    // MARK: log
    public static let logTag = "Ble.P"
    
    // MARK: var
    /// 持有的外围设备
    public let peripheral: CBPeripheral
    /// 广播数据
    public let advertisementData: [String : Any]
    /// 信号强度
    public let RSSI: NSNumber
    /// 广播时间
    public let discoverDate: Date
    /// 日志记录时间
    public var logDate: Date?
    
    // MARK: plugin
    public var plugins = [XYPeripheralPlugin]()
    
    // MARK: init
    init(peripheral: CBPeripheral, advertisementData: [String : Any], RSSI: NSNumber, discoverDate: Date) {
        self.peripheral = peripheral
        self.advertisementData = advertisementData
        self.RSSI = RSSI
        self.discoverDate = discoverDate
        super.init()
        self.peripheral.delegate = self
        addObservers()
    }
    deinit {
        removeObservers()
    }
}

// MARK: - func
extension XYPeripheralAgent {
    public func getCharacteristic(uuidString: String) -> CBCharacteristic? {
        var target: CBCharacteristic?
        let services = peripheral.services ?? []
        for service in services {
            let characteristics = service.characteristics ?? []
            for characteristic in characteristics {
                if characteristic.uuid.uuidString == uuidString {
                    target = characteristic
                    break
                }
            }
        }
        return target
    }
}

// MARK: - CBPeripheralDelegate
extension XYPeripheralAgent: CBPeripheralDelegate {
    // delegate
    public func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        let logTag = [Self.logTag, "didUpdateName()"]
        XYLog.info(tag: logTag)
        plugins.forEach { plugin in
            plugin.peripheralDidUpdateName?(peripheral)
        }
    }
    
    // delegate
    public func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        let logTag = [Self.logTag, "didModifyServices()"]
        XYLog.info(tag: logTag, content: "invalidatedServices=\(invalidatedServices)")
        plugins.forEach { plugin in
            plugin.peripheral?(peripheral, didModifyServices: invalidatedServices)
        }
    }

    // delegate
    public func peripheralDidUpdateRSSI(_ peripheral: CBPeripheral, error: (any Error)?) {
        let logTag = [Self.logTag, "didUpdateRSSI()"]
        if let error = error {
            XYLog.info(tag: logTag, content: "error=\(error.info)")
        } else {
            XYLog.info(tag: logTag)
        }
        plugins.forEach { plugin in
            plugin.peripheralDidUpdateRSSI?(peripheral, error: error)
        }
    }
}

// MARK: - readRSSI
extension XYPeripheralAgent {
    public func readRSSI() {
        let logTag = [Self.logTag, "readRSSI()"]
        XYLog.info(tag: logTag, process: .begin)
        peripheral.readRSSI()
        plugins.forEach { plugin in
            plugin.peripheralDidTryReadRSSI(peripheral)
        }
    }
}
extension XYPeripheralAgent {
    // delegate
    public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: (any Error)?) {
        let logTag = [Self.logTag, "didReadRSSI()"]
        if let error = error {
            XYLog.info(tag: logTag, content: "RSSI=\(RSSI)", "error=\(error.info)")
        } else {
            XYLog.info(tag: logTag, content: "RSSI=\(RSSI)")
        }
        plugins.forEach { plugin in
            plugin.peripheral?(peripheral, didReadRSSI: RSSI, error: error)
        }
    }
}

// MARK: - discoverServices
extension XYPeripheralAgent {
    public func discoverServices(serviceUUIDs: [CBUUID]?) {
        let logTag = [Self.logTag, "discoverServices()"]
        XYLog.info(tag: logTag, process: .begin, content: "uuids=\(serviceUUIDs)")
        peripheral.discoverServices(serviceUUIDs)
        plugins.forEach { plugin in
            plugin.peripheral(peripheral, didTryDiscoverServices: serviceUUIDs)
        }
    }
}
extension XYPeripheralAgent {
    // delegate
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        let logTag = [Self.logTag, "didDiscoverServices()"]
        if let error = error {
            XYLog.info(tag: logTag, content: "error=\(error.info)")
        } else {
            XYLog.info(tag: logTag)
        }
        plugins.forEach { plugin in
            plugin.peripheral?(peripheral, didDiscoverServices: error)
        }
    }
}

// MARK: - discoverIncludedServicesForService
extension XYPeripheralAgent {
    public func discoverIncludedServices(includedServiceUUIDs: [CBUUID]?, for service: CBService) {
        let logTag = [Self.logTag, "discoverIncludedServicesForService()"]
        XYLog.info(tag: logTag, process: .begin, content: "uuids=\(includedServiceUUIDs)", "service=\(service.info)")
        peripheral.discoverIncludedServices(includedServiceUUIDs, for: service)
        plugins.forEach { plugin in
            plugin.peripheral(peripheral, didTryDiscoverIncludedServices: includedServiceUUIDs, for: service)
        }
    }
}
extension XYPeripheralAgent {
    // delegate
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: (any Error)?) {
        let logTag = [Self.logTag, "didDiscoverIncludedServicesForService()"]
        if let error = error {
            XYLog.info(tag: logTag, content: "service=\(service.info)", "error=\(error.info)")
        } else {
            XYLog.info(tag: logTag, content: "service=\(service.info)")
        }
        plugins.forEach { plugin in
            plugin.peripheral?(peripheral, didDiscoverIncludedServicesFor: service, error: error)
        }
    }
}

// MARK: - discoverCharacteristicsForService
extension XYPeripheralAgent {
    public func discoverCharacteristics(characteristicUUIDs: [CBUUID]?, for service: CBService) {
        let logTag = [Self.logTag, "discoverCharacteristicsForService()"]
        XYLog.info(tag: logTag, process: .begin, content: "uuids=\(characteristicUUIDs)", "service=\(service.info)")
        peripheral.discoverCharacteristics(characteristicUUIDs, for: service)
        plugins.forEach { plugin in
            plugin.peripheral(peripheral, didTryDiscoverCharacteristics: characteristicUUIDs, for: service)
        }
    }
}
extension XYPeripheralAgent {
    // delegate
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        let logTag = [Self.logTag, "didDiscoverCharacteristicsForService()"]
        if let error = error {
            XYLog.info(tag: logTag, content: "service=\(service.info)", "error=\(error.info)")
        } else {
            XYLog.info(tag: logTag, content: "service=\(service.info)")
        }
        plugins.forEach { plugin in
            plugin.peripheral?(peripheral, didDiscoverCharacteristicsFor: service, error: error)
        }
    }
}

// MARK: - readValueForCharacteristic
extension XYPeripheralAgent {
    public func readValue(for characteristic: CBCharacteristic) {
        let logTag = [Self.logTag, "readValueForCharacteristic()"]
        XYLog.info(tag: logTag, process: .begin, content: "characteristic=\(characteristic.info)")
        peripheral.readValue(for: characteristic)
        plugins.forEach { plugin in
            plugin.peripheral(peripheral, didTryReadValueFor: characteristic)
        }
    }
}
extension XYPeripheralAgent {
    // delegate
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let logTag = [Self.logTag, "didUpdateValueForCharacteristic()"]
        if let error = error {
            XYLog.info(tag: logTag, content: "characteristic=\(characteristic.info)", "error=\(error.info)")
        } else {
            XYLog.info(tag: logTag, content: "characteristic=\(characteristic.info)")
        }
        plugins.forEach { plugin in
            plugin.peripheral?(peripheral, didUpdateValueFor: characteristic, error: error)
        }
    }
}

// MARK: - writeValueForCharacteristic
extension XYPeripheralAgent {
    public func writeValue(data: Data, for characteristic: CBCharacteristic, type: CBCharacteristicWriteType) {
        let logTag = [Self.logTag, "writeValueForCharacteristic()"]
        XYLog.info(tag: logTag, process: .begin, content: "characteristic=\(characteristic.info)", "type=\(type.info)")
        peripheral.writeValue(data, for: characteristic, type: type)
        plugins.forEach { plugin in
            plugin.peripheral(peripheral, didTryWriteValue: data, for: characteristic, type: type)
        }
    }
}
extension XYPeripheralAgent {
    // delegate
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        let logTag = [Self.logTag, "didWriteValueForCharacteristic()"]
        if let error = error {
            XYLog.info(tag: logTag, content: "characteristic=\(characteristic.info)", "error=\(error.info)")
        } else {
            XYLog.info(tag: logTag, content: "characteristic=\(characteristic.info)")
        }
        plugins.forEach { plugin in
            plugin.peripheral?(peripheral, didWriteValueFor: characteristic, error: error)
        }
    }
}

// MARK: - setNotifyValueForCharacteristic
extension XYPeripheralAgent {
    public func setNotifyValue(enabled: Bool, for characteristic: CBCharacteristic) {
        let logTag = [Self.logTag, "setNotifyValueForCharacteristic()"]
        XYLog.info(tag: logTag, process: .begin, content: "enabled=\(enabled)", "characteristic=\(characteristic.info)")
        peripheral.setNotifyValue(enabled, for: characteristic)
        plugins.forEach { plugin in
            plugin.peripheral(peripheral, didTrySetNotifyValue: enabled, for: characteristic)
        }
    }
}
extension XYPeripheralAgent {
    // delegate
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        let logTag = [Self.logTag, "didUpdateNotificationStateForCharacteristic()"]
        if let error = error {
            XYLog.info(tag: logTag, content: "characteristic=\(characteristic.info)", "error=\(error.info)")
        } else {
            XYLog.info(tag: logTag, content: "characteristic=\(characteristic.info)")
        }
        plugins.forEach { plugin in
            plugin.peripheral?(peripheral, didUpdateNotificationStateFor: characteristic, error: error)
        }
    }
}

// MARK: - discoverDescriptorsForCharacteristic
extension XYPeripheralAgent {
    public func discoverDescriptors(for characteristic: CBCharacteristic) {
        let logTag = [Self.logTag, "discoverDescriptorsForCharacteristic()"]
        XYLog.info(tag: logTag, process: .begin, content: "characteristic=\(characteristic.info)")
        peripheral.discoverDescriptors(for: characteristic)
        plugins.forEach { plugin in
            plugin.peripheral(peripheral, didTryDiscoverDescriptorsFor: characteristic)
        }
    }
}
extension XYPeripheralAgent {
    // delegate
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: (any Error)?) {
        let logTag = [Self.logTag, "didDiscoverDescriptorsForCharacteristic()"]
        if let error = error {
            XYLog.info(tag: logTag, content: "characteristic=\(characteristic.info)", "error=\(error.info)")
        } else {
            XYLog.info(tag: logTag, content: "characteristic=\(characteristic.info)")
        }
        plugins.forEach { plugin in
            plugin.peripheral?(peripheral, didDiscoverDescriptorsFor: characteristic, error: error)
        }
    }
}

// MARK: - readValueForDescriptor
extension XYPeripheralAgent {
    public func readValue(for descriptor: CBDescriptor) {
        let logTag = [Self.logTag, "readValueForDescriptor()"]
        XYLog.info(tag: logTag, process: .begin, content: "descriptor=\(descriptor.info)")
        peripheral.readValue(for: descriptor)
        plugins.forEach { plugin in
            plugin.peripheral(peripheral, didTryReadValueFor: descriptor)
        }
    }
}
extension XYPeripheralAgent {
    // delegate
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: (any Error)?) {
        let logTag = [Self.logTag, "didUpdateValueForDescriptor()"]
        if let error = error {
            XYLog.info(tag: logTag, content: "descriptor=\(descriptor.info)", "error=\(error.info)")
        } else {
            XYLog.info(tag: logTag, content: "descriptor=\(descriptor.info)")
        }
        plugins.forEach { plugin in
            plugin.peripheral?(peripheral, didUpdateValueFor: descriptor, error: error)
        }
    }
}

// MARK: - writeValueForDescriptor
extension XYPeripheralAgent {
    public func writeValue(data: Data, for descriptor: CBDescriptor) {
        let logTag = [Self.logTag, "writeValueForDescriptor()"]
        XYLog.info(tag: logTag, process: .begin, content: "descriptor=\(descriptor.info)")
        peripheral.writeValue(data, for: descriptor)
        plugins.forEach { plugin in
            plugin.peripheral(peripheral, didTryWriteValue: data, for: descriptor)
        }
    }
}
extension XYPeripheralAgent {
    // delegate
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: (any Error)?) {
        let logTag = [Self.logTag, "didWriteValueForDescriptor()"]
        if let error = error {
            XYLog.info(tag: logTag, content: "descriptor=\(descriptor.info)", "error=\(error.info)")
        } else {
            XYLog.info(tag: logTag, content: "descriptor=\(descriptor.info)")
        }
        plugins.forEach { plugin in
            plugin.peripheral?(peripheral, didWriteValueFor: descriptor, error: error)
        }
    }
}

// MARK: - writeValueForDescriptor
extension XYPeripheralAgent {
    public func openL2CAPChannel(PSM: CBL2CAPPSM) {
        let logTag = [Self.logTag, "openL2CAPChannel()"]
        XYLog.info(tag: logTag, process: .begin, content: "PSM=\(PSM)")
        peripheral.openL2CAPChannel(PSM)
        plugins.forEach { plugin in
            plugin.peripheral(peripheral, didTryOpenL2CAPChannel: PSM)
        }
    }
}
extension XYPeripheralAgent {
    // delegate
    public func peripheral(_ peripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: (any Error)?) {
        let logTag = [Self.logTag, "didOpenL2CAPChannel()"]
        if let error = error {
            XYLog.info(tag: logTag, content: "channel=\(channel?.info ?? "nil")", "error=\(error.info)")
        } else {
            XYLog.info(tag: logTag, content: "channel=\(channel?.info ?? "nil")")
        }
        plugins.forEach { plugin in
            plugin.peripheral?(peripheral, didOpen: channel, error: error)
        }
    }
}

// MARK: - KVO
extension XYPeripheralAgent {
    private func addObservers() {
        peripheral.addObserver(self, forKeyPath: "state", options: .new, context: nil)
    }
    
    private func removeObservers() {
        peripheral.removeObserver(self, forKeyPath: "state")
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        let logTag = [Self.logTag, "KVO"]
        if let peripheral = object as? CBPeripheral, peripheral == self.peripheral {
            if keyPath == "state", let state = change?[.newKey] as? CBPeripheralState {
                XYLog.info(tag: logTag, content: "peripheral.state=\(state.info)")
                return
            }
            return
        }
    }
}
