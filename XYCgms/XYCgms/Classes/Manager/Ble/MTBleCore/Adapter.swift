//
//  Adapter.swift
//  Pods
//
//  Created by hsf on 2025/9/11.
//

import Foundation
import CoreBluetooth
import MTBleCore
import XYCoreBluetooth
import XYLog

// MARK: - MTBleAdapter
extension XYCgmsBleManager {
    internal func configBleCoreAdapter() {
        MTBleAdapter.shared().startScanBlock = {
            [weak self] in
            let logTag = [Self.logTag, "Core", "startScanBlock"]
            XYLog.info(tag: logTag)
            let serviceUUID = CBUUID(string: Self.serviceUuid181F)
            let serviceUUIDs = [serviceUUID]
            let options: [String : Any] = [
               CBCentralManagerScanOptionSolicitedServiceUUIDsKey: serviceUUIDs,
               CBCentralManagerScanOptionAllowDuplicatesKey: true
            ]
            XYCentralManagerAgent.shared.scanForPeripherals(withServices: serviceUUIDs, options: options)
        }
        MTBleAdapter.shared().stopScanBlock = {
            [weak self] in
            let logTag = [Self.logTag, "Core", "stopScanBlock"]
            XYLog.info(tag: logTag)
            XYCentralManagerAgent.shared.stopScan()
        }
        MTBleAdapter.shared().readyToConnectBlock = {
            [weak self] uuidString in
            let logTag = [Self.logTag, "Core", "readyToConnectBlock"]
            XYLog.info(tag: logTag, process: .begin, content: "uuidString=\(uuidString)")
            guard let uuid = UUID(uuidString: uuidString) else {
                XYLog.info(tag: logTag, process: .fail("uuid=nil"))
                return false
            }
            let peripherals = XYCentralManagerAgent.shared.centralManager.retrievePeripherals(withIdentifiers: [uuid])
            return peripherals.count > 0
        }
        MTBleAdapter.shared().connectBlock = {
            [weak self] uuidString in
            let logTag = [Self.logTag, "Core", "connectBlock"]
            XYLog.info(tag: logTag, process: .begin, content: "uuidString=\(uuidString)")
            guard let uuid = UUID(uuidString: uuidString) else {
                XYLog.info(tag: logTag, process: .fail("uuid=nil"))
                MTBleAdapter.shared().onConnectFailure()
                return
            }
            let peripherals = XYCentralManagerAgent.shared.centralManager.retrievePeripherals(withIdentifiers: [uuid])
            guard let peripheral = peripherals.first else {
                XYLog.info(tag: logTag, process: .fail("retrievePeripheral=nil"))
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
            XYCentralManagerAgent.shared.connect(peripheral, options: options)
        }
        MTBleAdapter.shared().disconnectBlock = {
            [weak self] in
            let logTag = [Self.logTag, "Core", "disconnectBlock"]
            guard let peripheralAgent = XYCentralManagerAgent.shared.lastPeripheralAgent else {
                XYLog.info(tag: logTag, process: .fail("lastPeripheralAgent=nil"))
                return
            }
            XYCentralManagerAgent.shared.cancelPeripheralConnection(peripheralAgent.peripheral)
        }
        MTBleAdapter.shared().writeBlock = {
            [weak self] data, uuidString in
            let logTag = [Self.logTag, "Core", "writeBlock"]
            XYLog.info(tag: logTag, process: .begin, content: "uuidString=\(uuidString)", "data=\(data.toHexString())")
            guard let uuidString = uuidString else {
                XYLog.info(tag: logTag, process: .fail("uuid=nil"))
                return
            }
            guard let peripheralAgent = XYCentralManagerAgent.shared.lastPeripheralAgent else {
                XYLog.info(tag: logTag, process: .fail("lastPeripheralAgent=nil"))
                return
            }
            let characteristic = peripheralAgent.getCharacteristic(uuidString: uuidString)
            guard let characteristic = characteristic else {
                XYLog.info(tag: logTag, process: .fail("characteristic=nil"))
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
                XYLog.info(tag: logTag, process: .fail("type=nil"))
                return
            }
            peripheralAgent.writeValue(data: data, for: characteristic, type: type)
        }
        MTBleAdapter.shared().readBlock = {
            [weak self] uuidString in
            let logTag = [Self.logTag, "Core", "readBlock"]
            XYLog.info(tag: logTag, process: .begin, content: "uuidString=\(uuidString)")
            guard let uuidString = uuidString else {
                XYLog.info(tag: logTag, process: .fail("uuid=nil"))
                return
            }
            guard let peripheralAgent = XYCentralManagerAgent.shared.lastPeripheralAgent else {
                XYLog.info(tag: logTag, process: .fail("lastPeripheralAgent=nil"))
                return
            }
            let characteristic = peripheralAgent.getCharacteristic(uuidString: uuidString)
            guard let characteristic = characteristic else {
                XYLog.info(tag: logTag, process: .fail("characteristic=nil"))
                return
            }
            peripheralAgent.readValue(for: characteristic)
        }
        MTBleAdapter.shared().enableBlock = {
            [weak self] uuidString in
            let logTag = [Self.logTag, "Core", "enableBlock"]
            XYLog.info(tag: logTag, process: .begin, content: "uuidString=\(uuidString)")
            guard let uuidString = uuidString else {
                XYLog.info(tag: logTag, process: .fail("uuid=nil"))
                return
            }
            guard let peripheralAgent = XYCentralManagerAgent.shared.lastPeripheralAgent else {
                XYLog.info(tag: logTag, process: .fail("lastPeripheralAgent=nil"))
                return
            }
            let characteristic = peripheralAgent.getCharacteristic(uuidString: uuidString)
            guard let characteristic = characteristic else {
                XYLog.info(tag: logTag, process: .fail("characteristic=nil"))
                return
            }
            peripheralAgent.setNotifyValue(enabled: true, for: characteristic)
        }
        MTBleAdapter.shared().advertisementBlock = {
            [weak self] controller in
            let logTag = [Self.logTag, "Core", "advertisementBlock"]
            XYLog.info(tag: logTag)
        }
        MTBleAdapter.shared().messageBlock = {
            [weak self] controller, message in
            let logTag = [Self.logTag, "Core", "messageBlock"]
            XYLog.info(tag: logTag)
           
        }
    }
}


