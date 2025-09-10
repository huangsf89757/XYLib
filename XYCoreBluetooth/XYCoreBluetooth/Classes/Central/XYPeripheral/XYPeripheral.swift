//
//  XYPeripheral.swift
//  Pods
//
//  Created by hsf on 2025/9/10.
//

import Foundation
import CoreBluetooth
import XYExtension
import XYUtil
import XYLog

public final class XYPeripheral: NSObject {
    // MARK: log
    public static let logTag = "Ble.P"
    
    // MARK: var
    /// 持有的外围设备
    public let peripheral: CBPeripheral
    
    // MARK: plugin
    public var plugins = [XYPeripheralPlugin]()
    
    // MARK: init
    public init(peripheral: CBPeripheral) {
        self.peripheral = peripheral
        super.init()
        self.peripheral.delegate = self
        addObservers()
    }
    deinit {
        removeObservers()
    }
}

// MARK: - CBPeripheralDelegate
extension XYPeripheral: CBPeripheralDelegate {
    public func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        let logTag = [Self.logTag, "didUpdateName()"]
        XYLog.info(tag: logTag)
        plugins.forEach { plugin in
            plugin.peripheralDidUpdateName?(peripheral)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        let logTag = [Self.logTag, "didModifyServices()"]
        XYLog.info(tag: logTag, content: "invalidatedServices=\(invalidatedServices)")
        plugins.forEach { plugin in
            plugin.peripheral?(peripheral, didModifyServices: invalidatedServices)
        }
    }

    public func peripheralDidUpdateRSSI(_ peripheral: CBPeripheral, error: (any Error)?) {
        let logTag = [Self.logTag, "didUpdateRSSI()"]
        if let error = error {
            XYLog.info(tag: logTag, content: "error=\(error.localizedDescription)")
        } else {
            XYLog.info(tag: logTag)
        }
        plugins.forEach { plugin in
            plugin.peripheralDidUpdateRSSI?(peripheral, error: error)
        }
    }
}

// MARK: - readRSSI
extension XYPeripheral {
    public func readRSSI() {
        let logTag = [Self.logTag, "readRSSI()"]
        XYLog.info(tag: logTag, process: .begin)
        peripheral.readRSSI()
        plugins.forEach { plugin in
            plugin.peripheralDidTryReadRSSI(peripheral)
        }
    }
}
extension XYPeripheral {
    public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: (any Error)?) {
        let logTag = [Self.logTag, "didReadRSSI()"]
        if let error = error {
            XYLog.info(tag: logTag, content: "RSSI=\(RSSI)", "error=\(error.localizedDescription)")
        } else {
            XYLog.info(tag: logTag, content: "RSSI=\(RSSI)")
        }
        plugins.forEach { plugin in
            plugin.peripheral?(peripheral, didReadRSSI: RSSI, error: error)
        }
    }
}

// MARK: - discoverServices
extension XYPeripheral {
    public func discoverServices(serviceUUIDs: [CBUUID]?) {
        let logTag = [Self.logTag, "discoverServices()"]
        XYLog.info(tag: logTag, process: .begin, content: "uuids=\(serviceUUIDs)")
        peripheral.discoverServices(serviceUUIDs)
        plugins.forEach { plugin in
            plugin.peripheral(peripheral, didTryDiscoverServices: serviceUUIDs)
        }
    }
}
extension XYPeripheral {
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        let logTag = [Self.logTag, "didDiscoverServices()"]
        if let error = error {
            XYLog.info(tag: logTag, content: "error=\(error.localizedDescription)")
        } else {
            XYLog.info(tag: logTag)
        }
        plugins.forEach { plugin in
            plugin.peripheral?(peripheral, didDiscoverServices: error)
        }
    }
}

// MARK: - discoverIncludedServicesForService
extension XYPeripheral {
    public func discoverIncludedServices(includedServiceUUIDs: [CBUUID]?, for service: CBService) {
        let logTag = [Self.logTag, "discoverIncludedServicesForService()"]
        XYLog.info(tag: logTag, process: .begin, content: "uuids=\(includedServiceUUIDs)", "service=\(service.info)")
        peripheral.discoverIncludedServices(includedServiceUUIDs, for: service)
        plugins.forEach { plugin in
            plugin.peripheral(peripheral, didTryDiscoverIncludedServices: includedServiceUUIDs, for: service)
        }
    }
}
extension XYPeripheral {
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: (any Error)?) {
        let logTag = [Self.logTag, "didDiscoverIncludedServicesForService()"]
        if let error = error {
            XYLog.info(tag: logTag, content: "service=\(service.info)", "error=\(error.localizedDescription)")
        } else {
            XYLog.info(tag: logTag, content: "service=\(service.info)")
        }
        plugins.forEach { plugin in
            plugin.peripheral?(peripheral, didDiscoverIncludedServicesFor: service, error: error)
        }
    }
}

// MARK: - discoverCharacteristicsForService
extension XYPeripheral {
    public func discoverCharacteristics(characteristicUUIDs: [CBUUID]?, for service: CBService) {
        let logTag = [Self.logTag, "discoverCharacteristicsForService()"]
        XYLog.info(tag: logTag, process: .begin, content: "uuids=\(characteristicUUIDs)", "service=\(service.info)")
        peripheral.discoverCharacteristics(characteristicUUIDs, for: service)
        plugins.forEach { plugin in
            plugin.peripheral(peripheral, didTryDiscoverCharacteristics: characteristicUUIDs, for: service)
        }
    }
}
extension XYPeripheral {
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        let logTag = [Self.logTag, "didDiscoverCharacteristicsForService()"]
        if let error = error {
            XYLog.info(tag: logTag, content: "service=\(service.info)", "error=\(error.localizedDescription)")
        } else {
            XYLog.info(tag: logTag, content: "service=\(service.info)")
        }
        plugins.forEach { plugin in
            plugin.peripheral?(peripheral, didDiscoverCharacteristicsFor: service, error: error)
        }
    }
}

// MARK: - readValueForCharacteristic
extension XYPeripheral {
    public func readValue(for characteristic: CBCharacteristic) {
        let logTag = [Self.logTag, "readValueForCharacteristic()"]
        XYLog.info(tag: logTag, process: .begin, content: "characteristic=\(characteristic.info)")
        peripheral.readValue(for: characteristic)
        plugins.forEach { plugin in
            plugin.peripheral(peripheral, didTryReadValueFor: characteristic)
        }
    }
}
extension XYPeripheral {
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let logTag = [Self.logTag, "didReadValueForCharacteristic()"]
        if let error = error {
            XYLog.info(tag: logTag, content: "characteristic=\(characteristic.info)", "error=\(error.localizedDescription)")
        } else {
            XYLog.info(tag: logTag, content: "characteristic=\(characteristic.info)")
        }
        plugins.forEach { plugin in
            plugin.peripheral?(peripheral, didUpdateValueFor: characteristic, error: error)
        }
    }
}

// MARK: - writeValueForCharacteristic
extension XYPeripheral {
    public func writeValue(data: Data, for characteristic: CBCharacteristic, type: CBCharacteristicWriteType) {
        let logTag = [Self.logTag, "writeValueForCharacteristic()"]
        XYLog.info(tag: logTag, process: .begin, content: "characteristic=\(characteristic.info)", "type=\(type.info)")
        peripheral.writeValue(data, for: characteristic, type: type)
        plugins.forEach { plugin in
            plugin.peripheral(peripheral, didTryWriteValue: data, for: characteristic, type: type)
        }
    }
}
extension XYPeripheral {
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        let logTag = [Self.logTag, "didWriteValueForCharacteristic()"]
        if let error = error {
            XYLog.info(tag: logTag, content: "characteristic=\(characteristic.info)", "error=\(error.localizedDescription)")
        } else {
            XYLog.info(tag: logTag, content: "characteristic=\(characteristic.info)")
        }
        plugins.forEach { plugin in
            plugin.peripheral?(peripheral, didWriteValueFor: characteristic, error: error)
        }
    }
}

// MARK: - updateNotificationStateForCharacteristic
extension XYPeripheral {
    public func setNotifyValue(enabled: Bool, for characteristic: CBCharacteristic) {
        let logTag = [Self.logTag, "updateNotificationStateForCharacteristic()"]
        XYLog.info(tag: logTag, process: .begin, content: "enabled=\(enabled)", "characteristic=\(characteristic.info)")
        peripheral.setNotifyValue(enabled, for: characteristic)
        plugins.forEach { plugin in
            plugin.peripheral(peripheral, didTrySetNotifyValue: enabled, for: characteristic)
        }
    }
}
extension XYPeripheral {
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        let logTag = [Self.logTag, "didUpdateNotificationStateForCharacteristic()"]
        if let error = error {
            XYLog.info(tag: logTag, content: "characteristic=\(characteristic.info)", "error=\(error.localizedDescription)")
        } else {
            XYLog.info(tag: logTag, content: "characteristic=\(characteristic.info)")
        }
        plugins.forEach { plugin in
            plugin.peripheral?(peripheral, didUpdateNotificationStateFor: characteristic, error: error)
        }
    }
}

// MARK: - discoverDescriptorsForCharacteristic
extension XYPeripheral {
    public func discoverDescriptors(for characteristic: CBCharacteristic) {
        let logTag = [Self.logTag, "discoverDescriptorsForCharacteristic()"]
        XYLog.info(tag: logTag, process: .begin, content: "characteristic=\(characteristic.info)")
        peripheral.discoverDescriptors(for: characteristic)
        plugins.forEach { plugin in
            plugin.peripheral(peripheral, didTryDiscoverDescriptorsFor: characteristic)
        }
    }
}
extension XYPeripheral {
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: (any Error)?) {
        let logTag = [Self.logTag, "didDiscoverDescriptorsForCharacteristic()"]
        if let error = error {
            XYLog.info(tag: logTag, content: "characteristic=\(characteristic.info)", "error=\(error.localizedDescription)")
        } else {
            XYLog.info(tag: logTag, content: "characteristic=\(characteristic.info)")
        }
        plugins.forEach { plugin in
            plugin.peripheral?(peripheral, didDiscoverDescriptorsFor: characteristic, error: error)
        }
    }
}

// MARK: - readValueForDescriptor
extension XYPeripheral {
    public func readValue(for descriptor: CBDescriptor) {
        let logTag = [Self.logTag, "readValueForDescriptor()"]
        XYLog.info(tag: logTag, process: .begin, content: "descriptor=\(descriptor.info)")
        peripheral.readValue(for: descriptor)
        plugins.forEach { plugin in
            plugin.peripheral(peripheral, didTryReadValueFor: descriptor)
        }
    }
}
extension XYPeripheral {
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: (any Error)?) {
        let logTag = [Self.logTag, "didReadValueForDescriptor()"]
        if let error = error {
            XYLog.info(tag: logTag, content: "descriptor=\(descriptor.info)", "error=\(error.localizedDescription)")
        } else {
            XYLog.info(tag: logTag, content: "descriptor=\(descriptor.info)")
        }
        plugins.forEach { plugin in
            plugin.peripheral?(peripheral, didUpdateValueFor: descriptor, error: error)
        }
    }
}

// MARK: - writeValueForDescriptor
extension XYPeripheral {
    public func writeValue(data: Data, for descriptor: CBDescriptor) {
        let logTag = [Self.logTag, "writeValueForDescriptor()"]
        XYLog.info(tag: logTag, process: .begin, content: "descriptor=\(descriptor.info)")
        peripheral.writeValue(data, for: descriptor)
        plugins.forEach { plugin in
            plugin.peripheral(peripheral, didTryWriteValue: data, for: descriptor)
        }
    }
}
extension XYPeripheral {
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: (any Error)?) {
        let logTag = [Self.logTag, "didWriteValueForDescriptor()"]
        if let error = error {
            XYLog.info(tag: logTag, content: "descriptor=\(descriptor.info)", "error=\(error.localizedDescription)")
        } else {
            XYLog.info(tag: logTag, content: "descriptor=\(descriptor.info)")
        }
        plugins.forEach { plugin in
            plugin.peripheral?(peripheral, didWriteValueFor: descriptor, error: error)
        }
    }
}

// MARK: - writeValueForDescriptor
extension XYPeripheral {
    public func openL2CAPChannel(PSM: CBL2CAPPSM) {
        let logTag = [Self.logTag, "openL2CAPChannel()"]
        XYLog.info(tag: logTag, process: .begin, content: "PSM=\(PSM)")
        peripheral.openL2CAPChannel(PSM)
        plugins.forEach { plugin in
            plugin.peripheral(peripheral, didTryOpenL2CAPChannel: PSM)
        }
    }
}
extension XYPeripheral {
    public func peripheral(_ peripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: (any Error)?) {
        let logTag = [Self.logTag, "didOpenL2CAPChannel()"]
        if let error = error {
            XYLog.info(tag: logTag, content: "channel=\(channel?.info ?? "nil")", "error=\(error.localizedDescription)")
        } else {
            XYLog.info(tag: logTag, content: "channel=\(channel?.info ?? "nil")")
        }
        plugins.forEach { plugin in
            plugin.peripheral?(peripheral, didOpen: channel, error: error)
        }
    }
}

// MARK: - KVO
extension XYPeripheral {
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
