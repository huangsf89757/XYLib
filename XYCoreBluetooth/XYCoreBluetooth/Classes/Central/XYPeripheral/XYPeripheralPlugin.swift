//
//  XYPeripheralPlugin.swift
//  Pods
//
//  Created by hsf on 2025/9/10.
//

import Foundation
import CoreBluetooth

public protocol XYPeripheralPlugin: CBPeripheralDelegate {
    func peripheralDidTryReadRSSI(_ peripheral: CBPeripheral)
    func peripheral(_ peripheral: CBPeripheral, didTryDiscoverServices serviceUUIDs: [CBUUID]?)
    func peripheral(_ peripheral: CBPeripheral, didTryDiscoverIncludedServices includedServiceUUIDs: [CBUUID]?, for service: CBService)
    func peripheral(_ peripheral: CBPeripheral, didTryDiscoverCharacteristics characteristicUUIDs: [CBUUID]?, for service: CBService)
    func peripheral(_ peripheral: CBPeripheral, didTryReadValueFor characteristic: CBCharacteristic)
    func peripheral(_ peripheral: CBPeripheral, didTryWriteValue data: Data, for characteristic: CBCharacteristic, type: CBCharacteristicWriteType)
    func peripheral(_ peripheral: CBPeripheral, didTrySetNotifyValue enabled: Bool, for characteristic: CBCharacteristic)
    func peripheral(_ peripheral: CBPeripheral, didTryDiscoverDescriptorsFor characteristic: CBCharacteristic)
    func peripheral(_ peripheral: CBPeripheral, didTryReadValueFor descriptor: CBDescriptor)
    func peripheral(_ peripheral: CBPeripheral, didTryWriteValue data: Data, for descriptor: CBDescriptor)
    func peripheral(_ peripheral: CBPeripheral, didTryOpenL2CAPChannel PSM: CBL2CAPPSM)
}

extension XYPeripheralPlugin {
    func peripheralDidTryReadRSSI(_ peripheral: CBPeripheral) {}
    func peripheral(_ peripheral: CBPeripheral, didTryDiscoverServices serviceUUIDs: [CBUUID]?) {}
    func peripheral(_ peripheral: CBPeripheral, didTryDiscoverIncludedServices includedServiceUUIDs: [CBUUID]?, for service: CBService) {}
    func peripheral(_ peripheral: CBPeripheral, didTryDiscoverCharacteristics characteristicUUIDs: [CBUUID]?, for service: CBService) {}
    func peripheral(_ peripheral: CBPeripheral, didTryReadValueFor characteristic: CBCharacteristic) {}
    func peripheral(_ peripheral: CBPeripheral, didTryWriteValue data: Data, for characteristic: CBCharacteristic, type: CBCharacteristicWriteType) {}
    func peripheral(_ peripheral: CBPeripheral, didTrySetNotifyValue enabled: Bool, for characteristic: CBCharacteristic) {}
    func peripheral(_ peripheral: CBPeripheral, didTryDiscoverDescriptorsFor characteristic: CBCharacteristic) {}
    func peripheral(_ peripheral: CBPeripheral, didTryReadValueFor descriptor: CBDescriptor) {}
    func peripheral(_ peripheral: CBPeripheral, didTryWriteValue data: Data, for descriptor: CBDescriptor) {}
    func peripheral(_ peripheral: CBPeripheral, didTryOpenL2CAPChannel PSM: CBL2CAPPSM) {}
}
