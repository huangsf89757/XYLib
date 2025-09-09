//
//  XYBlePeripheral.swift
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
    func setupPeripheral() {
        
    }
}

// MARK: - CBPeripheralDelegate
extension XYBleManager: CBPeripheralDelegate {
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        let logTag = [Self.logTag, "didDiscoverServices()"]
        if let error = error {
            XYLog.info(tag: logTag, content: "error=\(error.localizedDescription)")
        } else {
            XYLog.info(tag: logTag)
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        let logTag = [Self.logTag, "didDiscoverCharacteristicsForService()"]
        if let error = error {
            XYLog.info(tag: logTag, content: "service=\(service.info)", "error=\(error.localizedDescription)")
        } else {
            XYLog.info(tag: logTag, content: "service=\(service.info)")
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        let logTag = [Self.logTag, "didUpdateNotificationStateForCharacteristic()"]
        if let error = error {
            XYLog.info(tag: logTag, content: "characteristic=\(characteristic.info)", "error=\(error.localizedDescription)")
        } else {
            XYLog.info(tag: logTag, content: "characteristic=\(characteristic.info)")
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let logTag = [Self.logTag, "didUpdateValueForCharacteristic()"]
        if let error = error {
            XYLog.info(tag: logTag, content: "characteristic=\(characteristic.info)", "error=\(error.localizedDescription)")
        } else {
            XYLog.info(tag: logTag, content: "characteristic=\(characteristic.info)")
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        let logTag = [Self.logTag, "didWriteValueForCharacteristic()"]
        if let error = error {
            XYLog.info(tag: logTag, content: "characteristic=\(characteristic.info)", "error=\(error.localizedDescription)")
        } else {
            XYLog.info(tag: logTag, content: "characteristic=\(characteristic.info)")
        }
    }
    
}
