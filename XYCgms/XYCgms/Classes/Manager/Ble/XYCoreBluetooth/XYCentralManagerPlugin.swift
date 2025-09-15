//
//  XYCentralManagerPlugin.swift
//  Pods
//
//  Created by hsf on 2025/9/11.
//

import Foundation
import CoreBluetooth
import MTBleCore
import XYCoreBluetooth
import XYLog

extension XYCgmsBleManager: XYCentralManagerPlugin {}

extension XYCgmsBleManager {
    public func centralManager(_ central: CBCentralManager, didTryScanForPeripherals serviceUUIDs: [CBUUID]?, options: [String : Any]?) {
        
    }
    
    public func centralManagerDidTryStopScan(_ central: CBCentralManager) {
        
    }
    
    public func centralManager(_ central: CBCentralManager, didTryConnect peripheral: CBPeripheral, options: [String : Any]?) {
        
    }
    
    public func centralManager(_ central: CBCentralManager, didConnectTimeout peripheral: CBPeripheral) {
        
    }
    
    public func centralManager(_ central: CBCentralManager, didTryCancelPeripheralConnection peripheral: CBPeripheral) {
        
    }
    
    public func centralManager(_ central: CBCentralManager, discoveredPeripheralsDidAdd uuid: UUID, peripheral: CBPeripheral) {

    }
    
    public func centralManager(_ central: CBCentralManager, discoveredPeripheralsDidRemove uuid: UUID) {

    }
}

extension XYCgmsBleManager {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {}

    public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {}

    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let uuid = peripheral.identifier.uuidString
        MTBleAdapter.shared().onAppleDidDiscoverPeripheral(uuid, advertisementData: advertisementData, rssi: RSSI)
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        let logTag = [Self.logTag, "Core", "discoverServices"]
        let uuid = peripheral.identifier
        XYLog.info(tag: logTag, process: .begin, content: "uuidString=\(uuid.uuidString)")
        guard let peripheralAgent = XYCentralManagerAgent.shared.discoveredPeripherals[uuid] else {
            XYLog.info(tag: logTag, process: .fail("peripheralAgent=nil"))
            return
        }
        peripheralAgent.plugins = [self]
        let serviceUUID = CBUUID(string: Self.serviceUuid181F)
        let serviceUUIDs = [serviceUUID]
        peripheralAgent.discoverServices(serviceUUIDs: serviceUUIDs)
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {}

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
        MTBleAdapter.shared().onDisconnected()
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, timestamp: CFAbsoluteTime, isReconnecting: Bool, error: (any Error)?) {
        MTBleAdapter.shared().onDisconnected()
    }

    public func centralManager(_ central: CBCentralManager, connectionEventDidOccur event: CBConnectionEvent, for peripheral: CBPeripheral) {}

    public func centralManager(_ central: CBCentralManager, didUpdateANCSAuthorizationFor peripheral: CBPeripheral) {}
}



