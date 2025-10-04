//
//  XYPeripheralDelegate.swift
//  Pods
//
//  Created by hsf on 2025/9/11.
//

import Foundation
import CoreBluetooth
import MTBleCore
import XYCoreBluetooth
import XYLog

extension XYCgmsBleManager: XYPeripheralDelegate {}

extension XYCgmsBleManager {
    public func peripheralDidTryReadRSSI(_ peripheral: CBPeripheral) {}
    
    public func peripheral(_ peripheral: CBPeripheral, didTryDiscoverServices serviceUUIDs: [CBUUID]?) {}
    
    public func peripheral(_ peripheral: CBPeripheral, didTryDiscoverIncludedServices includedServiceUUIDs: [CBUUID]?, for service: CBService) {}
    
    public func peripheral(_ peripheral: CBPeripheral, didTryDiscoverCharacteristics characteristicUUIDs: [CBUUID]?, for service: CBService) {}
    
    public func peripheral(_ peripheral: CBPeripheral, didTryReadValueFor characteristic: CBCharacteristic) {}
    
    public func peripheral(_ peripheral: CBPeripheral, didTryWriteValue data: Data, for characteristic: CBCharacteristic, type: CBCharacteristicWriteType) {}
    
    public func peripheral(_ peripheral: CBPeripheral, didTrySetNotifyValue enabled: Bool, for characteristic: CBCharacteristic) {}
    
    public func peripheral(_ peripheral: CBPeripheral, didTryDiscoverDescriptorsFor characteristic: CBCharacteristic) {}
    
    public func peripheral(_ peripheral: CBPeripheral, didTryReadValueFor descriptor: CBDescriptor) {}
    
    public func peripheral(_ peripheral: CBPeripheral, didTryWriteValue data: Data, for descriptor: CBDescriptor) {}
    
    public func peripheral(_ peripheral: CBPeripheral, didTryOpenL2CAPChannel PSM: CBL2CAPPSM) {}
}

extension XYCgmsBleManager {
    public func peripheralDidUpdateName(_ peripheral: CBPeripheral) {}

    public func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {}

    public func peripheralDidUpdateRSSI(_ peripheral: CBPeripheral, error: (any Error)?) {}

    public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: (any Error)?) {}

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        guard error == nil else { return }
        let logTag = [Self.logTag, "Core", "discoverCharacteristicsForService"]
        let uuid = peripheral.identifier
        XYLog.info(tag: logTag, process: .begin, content: "uuidString=\(uuid.uuidString)")
        guard let peripheralAgent = XYCentralManagerAgent.shared.discoveredPeripherals[uuid] else {
            XYLog.info(tag: logTag, process: .fail, content: "peripheralAgent=nil")
            return
        }
        let services = peripheral.services ?? []
        let characteristicUUIDF001 = CBUUID(string: Self.characteristicUuidF001)
        let characteristicUUIDF002 = CBUUID(string: Self.characteristicUuidF002)
        let characteristicUUIDF003 = CBUUID(string: Self.characteristicUuidF003)
        let characteristicUUIDF005 = CBUUID(string: Self.characteristicUuidF005)
        let characteristicUUIDs = [
            characteristicUUIDF001,
            characteristicUUIDF002,
            characteristicUUIDF003,
            characteristicUUIDF005,
        ]
        services.forEach { service in
            peripheralAgent.discoverCharacteristics(characteristicUUIDs: characteristicUUIDs, for: service)
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: (any Error)?) {}

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
        guard error == nil else { return }
        let logTag = [Self.logTag, "Core", "setNotifyValueForService"]
        let uuid = peripheral.identifier
        XYLog.info(tag: logTag, process: .begin, content: "uuidString=\(uuid.uuidString)")
        guard let peripheralAgent = XYCentralManagerAgent.shared.discoveredPeripherals[uuid] else {
            XYLog.info(tag: logTag, process: .fail, content: "peripheralAgent=nil")
            return
        }
        let characteristics = service.characteristics ?? []
        characteristics.forEach { characteristic in
            peripheralAgent.setNotifyValue(enabled: true, for: characteristic)
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        guard error == nil else {
            XYCentralManagerAgent.shared.cancelPeripheralConnection(peripheral)
            return
        }
        guard let value = characteristic.value else {
            XYCentralManagerAgent.shared.cancelPeripheralConnection(peripheral)
            return
        }
        MTBleAdapter.shared().onReceiveValue(value, forCharacteristicUUid: characteristic.uuid.uuidString)
    }

    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        guard error == nil else { return }
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: (any Error)?) {
        guard error == nil else {
            XYCentralManagerAgent.shared.cancelPeripheralConnection(peripheral)
            return
        }
        let uuidString = characteristic.uuid.uuidString
        MTBleAdapter.shared().onCharacteristicNotifyEnable(uuidString)
        if uuidString == Self.characteristicUuidF002 {
            MTBleAdapter.shared().onConnectSuccess()
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: (any Error)?) {}

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: (any Error)?) {}

    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: (any Error)?) {}

    public func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {}

    public func peripheral(_ peripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: (any Error)?) {}
}
