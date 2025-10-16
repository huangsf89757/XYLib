//
//  XYPeripheralManagerDelegate.swift
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

// MARK: - XYPeripheralManagerDelegate
/// 外设管理器代理协议，继承自 CBPeripheralManagerDelegate，并补充发起操作通知
public protocol XYPeripheralManagerDelegate: CBPeripheralManagerDelegate {
    // advertising
    func peripheralManager(_ peripheral: CBPeripheralManager, startAdvertising advertisementData: [String: Any]?)
    func peripheralManager(_ peripheral: CBPeripheralManager, stopAdvertising: Void)

    // services
    func peripheralManager(_ peripheral: CBPeripheralManager, add service: CBMutableService)
    func peripheralManager(_ peripheral: CBPeripheralManager, remove service: CBMutableService)
    func peripheralManager(_ peripheral: CBPeripheralManager, removeAllServices: Void)

    // latency
    func peripheralManager(_ peripheral: CBPeripheralManager, setDesiredConnectionLatency latency: CBPeripheralManagerConnectionLatency, for central: CBCentral)

    // I/O
    func peripheralManager(_ peripheral: CBPeripheralManager, updateValue value: Data, for characteristic: CBMutableCharacteristic, onSubscribedCentrals centrals: [CBCentral]?, returns ok: Bool)
    func peripheralManager(_ peripheral: CBPeripheralManager, respondTo request: CBATTRequest, withResult result: CBATTError.Code)

    // L2CAP
    @available(iOS 11.0, *)
    func peripheralManager(_ peripheral: CBPeripheralManager, publishL2CAPChannelWithEncryption encryptionRequired: Bool)
    @available(iOS 11.0, *)
    func peripheralManager(_ peripheral: CBPeripheralManager, unpublishL2CAPChannel PSM: CBL2CAPPSM)
}

// MARK: - Default Implementation
public extension XYPeripheralManagerDelegate {
    func peripheralManager(_ peripheral: CBPeripheralManager, startAdvertising advertisementData: [String: Any]?) {}
    func peripheralManager(_ peripheral: CBPeripheralManager, stopAdvertising: Void) {}
    func peripheralManager(_ peripheral: CBPeripheralManager, add service: CBMutableService) {}
    func peripheralManager(_ peripheral: CBPeripheralManager, remove service: CBMutableService) {}
    func peripheralManager(_ peripheral: CBPeripheralManager, removeAllServices: Void) {}
    func peripheralManager(_ peripheral: CBPeripheralManager, setDesiredConnectionLatency latency: CBPeripheralManagerConnectionLatency, for central: CBCentral) {}
    func peripheralManager(_ peripheral: CBPeripheralManager, updateValue value: Data, for characteristic: CBMutableCharacteristic, onSubscribedCentrals centrals: [CBCentral]?, returns ok: Bool) {}
    func peripheralManager(_ peripheral: CBPeripheralManager, respondTo request: CBATTRequest, withResult result: CBATTError.Code) {}
    @available(iOS 11.0, *)
    func peripheralManager(_ peripheral: CBPeripheralManager, publishL2CAPChannelWithEncryption encryptionRequired: Bool) {}
    @available(iOS 11.0, *)
    func peripheralManager(_ peripheral: CBPeripheralManager, unpublishL2CAPChannel PSM: CBL2CAPPSM) {}
}


