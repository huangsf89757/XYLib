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

public final class XYPeripheralAgent: NSObject, CBPeripheralDelegate {
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
    /// 特征缓存
    private var characteristicCache: [String: CBCharacteristic] = [:]
    
    // MARK: plugin
    public weak var delegate: XYPeripheralDelegate?
    
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
        // 先从缓存中查找
        if let cached = characteristicCache[uuidString] {
            return cached
        }
        
        // 缓存未命中，执行查找
        var target: CBCharacteristic?
        let services = peripheral.services ?? []
        for service in services {
            let characteristics = service.characteristics ?? []
            for characteristic in characteristics {
                if characteristic.uuid.uuidString == uuidString {
                    target = characteristic
                    // 存入缓存
                    characteristicCache[uuidString] = characteristic
                    break
                }
            }
        }
        return target
    }
    
    /// 清除特征缓存（当服务或特征发生变化时调用）
    public func clearCharacteristicCache() {
        characteristicCache.removeAll()
    }
}

// MARK: - readRSSI
extension XYPeripheralAgent {
    public func readRSSI() {
        let logTag = [Self.logTag, "readRSSI()"]
        XYLog.info(tag: logTag, process: .begin)
        peripheral.readRSSI()
        delegate?.peripheralDidTryReadRSSI(peripheral)
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
        delegate?.peripheral?(peripheral, didReadRSSI: RSSI, error: error)
    }
}

// MARK: - discoverServices
extension XYPeripheralAgent {
    public func discoverServices(serviceUUIDs: [CBUUID]?) {
        let logTag = [Self.logTag, "discoverServices()"]
        XYLog.info(tag: logTag, process: .begin, content: "uuids=\(serviceUUIDs)")
        peripheral.discoverServices(serviceUUIDs)
        delegate?.peripheral(peripheral, didTryDiscoverServices: serviceUUIDs)
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
            // 发现服务成功时清除特征缓存
            clearCharacteristicCache()
        }
        delegate?.peripheral?(peripheral, didDiscoverServices: error)
    }
}

// MARK: - discoverIncludedServicesForService
extension XYPeripheralAgent {
    public func discoverIncludedServices(includedServiceUUIDs: [CBUUID]?, for service: CBService) {
        let logTag = [Self.logTag, "discoverIncludedServicesForService()"]
        XYLog.info(tag: logTag, process: .begin, content: "uuids=\(includedServiceUUIDs)", "service=\(service.info)")
        peripheral.discoverIncludedServices(includedServiceUUIDs, for: service)
        delegate?.peripheral(peripheral, didTryDiscoverIncludedServices: includedServiceUUIDs, for: service)
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
        delegate?.peripheral?(peripheral, didDiscoverIncludedServicesFor: service, error: error)
    }
}

// MARK: - discoverCharacteristicsForService
extension XYPeripheralAgent {
    public func discoverCharacteristics(characteristicUUIDs: [CBUUID]?, for service: CBService) {
        let logTag = [Self.logTag, "discoverCharacteristicsForService()"]
        XYLog.info(tag: logTag, process: .begin, content: "uuids=\(characteristicUUIDs)", "service=\(service.info)")
        peripheral.discoverCharacteristics(characteristicUUIDs, for: service)
        delegate?.peripheral(peripheral, didTryDiscoverCharacteristics: characteristicUUIDs, for: service)
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
        delegate?.peripheral?(peripheral, didDiscoverCharacteristicsFor: service, error: error)
    }
}

// MARK: - readValueForCharacteristic
extension XYPeripheralAgent {
    public func readValue(for characteristic: CBCharacteristic) {
        let logTag = [Self.logTag, "readValueForCharacteristic()"]
        XYLog.info(tag: logTag, process: .begin, content: "characteristic=\(characteristic.info)")
        guard characteristic.properties.contains(.read) else {
            let error = NSError(domain: "XYCoreBluetooth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Characteristic does not support read operation"])
            XYLog.info(tag: logTag, process: .fail, content: "properties dose not contain read")
            // 即使属性检查失败，也调用委托方法，让调用者处理错误
            delegate?.peripheral?(peripheral, didUpdateValueFor: characteristic, error: error)
            return
        }
        peripheral.readValue(for: characteristic)
        delegate?.peripheral(peripheral, didTryReadValueFor: characteristic)
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
        delegate?.peripheral?(peripheral, didUpdateValueFor: characteristic, error: error)
    }
}

// MARK: - writeValueForCharacteristic
extension XYPeripheralAgent {
    public func writeValue(data: Data, for characteristic: CBCharacteristic, type: CBCharacteristicWriteType) {
        let logTag = [Self.logTag, "writeValueForCharacteristic()"]
        XYLog.info(tag: logTag, process: .begin, content: "characteristic=\(characteristic.info)", "type=\(type.info)")
        
        var propertyCheckFailed = false
        var errorMessage = ""
        
        switch type {
        case .withResponse:
            guard characteristic.properties.contains(.write) else {
                propertyCheckFailed = true
                errorMessage = "properties dose not contain write"
                break
            }
        case .withoutResponse:
            guard characteristic.properties.contains(.writeWithoutResponse) else {
                propertyCheckFailed = true
                errorMessage = "properties dose not contain withoutResponse"
                break
            }
        @unknown default:
            propertyCheckFailed = true
            errorMessage = "unknown write type"
            break
        }
        
        if propertyCheckFailed {
            let error = NSError(domain: "XYCoreBluetooth", code: -2, userInfo: [NSLocalizedDescriptionKey: errorMessage])
            XYLog.info(tag: logTag, process: .fail, content:errorMessage)
            // 即使属性检查失败，也调用委托方法，让调用者处理错误
            delegate?.peripheral?(peripheral, didWriteValueFor: characteristic, error: error)
            return
        }
        
        peripheral.writeValue(data, for: characteristic, type: type)
        delegate?.peripheral(peripheral, didTryWriteValue: data, for: characteristic, type: type)
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
        delegate?.peripheral?(peripheral, didWriteValueFor: characteristic, error: error)
    }
}

// MARK: - setNotifyValueForCharacteristic
extension XYPeripheralAgent {
    public func setNotifyValue(enabled: Bool, for characteristic: CBCharacteristic) {
        let logTag = [Self.logTag, "setNotifyValueForCharacteristic()"]
        XYLog.info(tag: logTag, process: .begin, content: "enabled=\(enabled)", "characteristic=\(characteristic.info)")
        guard characteristic.properties.canSubscribe else {
            let error = NSError(domain: "XYCoreBluetooth", code: -3, userInfo: [NSLocalizedDescriptionKey: "subscribe not supported (no notify/indicate)"])
            XYLog.info(tag: logTag, process: .fail, content: "subscribe not supported (no notify/indicate)")
            // 即使属性检查失败，也调用委托方法，让调用者处理错误
            delegate?.peripheral?(peripheral, didUpdateNotificationStateFor: characteristic, error: error)
            return
        }
        peripheral.setNotifyValue(enabled, for: characteristic)
        delegate?.peripheral(peripheral, didTrySetNotifyValue: enabled, for: characteristic)
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
        delegate?.peripheral?(peripheral, didUpdateNotificationStateFor: characteristic, error: error)
    }
}

// MARK: - discoverDescriptorsForCharacteristic
extension XYPeripheralAgent {
    public func discoverDescriptors(for characteristic: CBCharacteristic) {
        let logTag = [Self.logTag, "discoverDescriptorsForCharacteristic()"]
        XYLog.info(tag: logTag, process: .begin, content: "characteristic=\(characteristic.info)")
        peripheral.discoverDescriptors(for: characteristic)
        delegate?.peripheral(peripheral, didTryDiscoverDescriptorsFor: characteristic)
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
        delegate?.peripheral?(peripheral, didDiscoverDescriptorsFor: characteristic, error: error)
    }
}

// MARK: - readValueForDescriptor
extension XYPeripheralAgent {
    public func readValue(for descriptor: CBDescriptor) {
        let logTag = [Self.logTag, "readValueForDescriptor()"]
        XYLog.info(tag: logTag, process: .begin, content: "descriptor=\(descriptor.info)")
        peripheral.readValue(for: descriptor)
        delegate?.peripheral(peripheral, didTryReadValueFor: descriptor)
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
        delegate?.peripheral?(peripheral, didUpdateValueFor: descriptor, error: error)
    }
}

// MARK: - writeValueForDescriptor
extension XYPeripheralAgent {
    public func writeValue(data: Data, for descriptor: CBDescriptor) {
        let logTag = [Self.logTag, "writeValueForDescriptor()"]
        XYLog.info(tag: logTag, process: .begin, content: "descriptor=\(descriptor.info)")
        peripheral.writeValue(data, for: descriptor)
        delegate?.peripheral(peripheral, didTryWriteValue: data, for: descriptor)
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
        delegate?.peripheral?(peripheral, didWriteValueFor: descriptor, error: error)
    }
}

// MARK: - writeValueForDescriptor
extension XYPeripheralAgent {
    public func openL2CAPChannel(PSM: CBL2CAPPSM) {
        let logTag = [Self.logTag, "openL2CAPChannel()"]
        XYLog.info(tag: logTag, process: .begin, content: "PSM=\(PSM)")
        peripheral.openL2CAPChannel(PSM)
        delegate?.peripheral(peripheral, didTryOpenL2CAPChannel: PSM)
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
        delegate?.peripheral?(peripheral, didOpen: channel, error: error)
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
