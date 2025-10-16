//
//  XYPeripheralDelegate.swift
//  XYCoreBluetooth
//
//  Created by hsf on 2025/10/16.
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

// MARK: - XYPeripheralDelegate
/// 蓝牙外设代理协议，继承自 CBPeripheralDelegate，扩展操作发起时机的通知
public protocol XYPeripheralDelegate: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, readRSSI: Void)

    func peripheral(_ peripheral: CBPeripheral, discoverServices serviceUUIDs: [CBUUID]?)

    func peripheral(_ peripheral: CBPeripheral, discoverIncludedServices includedServiceUUIDs: [CBUUID]?, for service: CBService)

    func peripheral(_ peripheral: CBPeripheral, discoverCharacteristics characteristicUUIDs: [CBUUID]?, for service: CBService)

    func peripheral(_ peripheral: CBPeripheral, readValueFor characteristic: CBCharacteristic)

    func peripheral(_ peripheral: CBPeripheral, writeValue data: Data, for characteristic: CBCharacteristic, type: CBCharacteristicWriteType)

    func peripheral(_ peripheral: CBPeripheral, setNotifyValue enabled: Bool, for characteristic: CBCharacteristic)

    func peripheral(_ peripheral: CBPeripheral, discoverDescriptorsFor characteristic: CBCharacteristic)

    func peripheral(_ peripheral: CBPeripheral, readValueFor descriptor: CBDescriptor)

    func peripheral(_ peripheral: CBPeripheral, writeValue data: Data, for descriptor: CBDescriptor)

    @available(iOS 9.0, *)
    func peripheral(_ peripheral: CBPeripheral, maximumWriteValueLengthFor type: CBCharacteristicWriteType, returns length: Int)
}

// MARK: - Default Implementation
public extension XYPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, readRSSI: Void) {}
    
    func peripheral(_ peripheral: CBPeripheral, discoverServices serviceUUIDs: [CBUUID]?) {}
    
    func peripheral(_ peripheral: CBPeripheral, discoverIncludedServices includedServiceUUIDs: [CBUUID]?, for service: CBService) {}
    
    func peripheral(_ peripheral: CBPeripheral, discoverCharacteristics characteristicUUIDs: [CBUUID]?, for service: CBService) {}
    
    func peripheral(_ peripheral: CBPeripheral, readValueFor characteristic: CBCharacteristic) {}
    
    func peripheral(_ peripheral: CBPeripheral, writeValue data: Data, for characteristic: CBCharacteristic, type: CBCharacteristicWriteType) {}
    
    func peripheral(_ peripheral: CBPeripheral, setNotifyValue enabled: Bool, for characteristic: CBCharacteristic) {}
    
    func peripheral(_ peripheral: CBPeripheral, discoverDescriptorsFor characteristic: CBCharacteristic) {}
    
    func peripheral(_ peripheral: CBPeripheral, readValueFor descriptor: CBDescriptor) {}
    
    func peripheral(_ peripheral: CBPeripheral, writeValue data: Data, for descriptor: CBDescriptor) {}
    
    @available(iOS 9.0, *)
    func peripheral(_ peripheral: CBPeripheral, maximumWriteValueLengthFor type: CBCharacteristicWriteType, returns length: Int) {}
}


