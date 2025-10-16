//
//  XYCentralManagerDelegate.swift
//  XYCoreBluetooth
//
//  Created by hsf on 2025/10/14.
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

public protocol XYCentralManagerDelegate: CBCentralManagerDelegate {
    @available(iOS 7.0, *)
    func centralManager(_ central: CBCentralManager, retrievePeripheralsWithIdentifiers identifiers: [UUID], returns peripherals: [CBPeripheral])
    
    @available(iOS 7.0, *)
    func centralManager(_ central: CBCentralManager, retrieveConnectedPeripheralsWithServices serviceUUIDs: [CBUUID], returns peripherals: [CBPeripheral])
    
    func centralManager(_ central: CBCentralManager, scanForPeripheralsWithServices serviceUUIDs: [CBUUID]?, options: [String: Any]?)
    
    func centralManager(_ central: CBCentralManager, stopScan: Void)
    
    func centralManager(_ central: CBCentralManager, connect peripheral: CBPeripheral, options: [String: Any]?)
    
    func centralManager(_ central: CBCentralManager, cancelPeripheralConnection peripheral: CBPeripheral)
    
    @available(iOS 13.0, *)
    func centralManager(_ central: CBCentralManager, registerForConnectionEventsWithOptions options: [CBConnectionEventMatchingOption: Any]?)
}

extension XYCentralManagerDelegate {
    @available(iOS 7.0, *)
    func centralManager(_ central: CBCentralManager, retrievePeripheralsWithIdentifiers identifiers: [UUID], returns peripherals: [CBPeripheral]) {}
    
    @available(iOS 7.0, *)
    func centralManager(_ central: CBCentralManager, retrieveConnectedPeripheralsWithServices serviceUUIDs: [CBUUID], returns peripherals: [CBPeripheral]) {}
    
    func centralManager(_ central: CBCentralManager, scanForPeripheralsWithServices serviceUUIDs: [CBUUID]?, options: [String: Any]?) {}
    
    func centralManager(_ central: CBCentralManager, stopScan: Void) {}
    
    func centralManager(_ central: CBCentralManager, connect peripheral: CBPeripheral, options: [String: Any]?) {}
    
    func centralManager(_ central: CBCentralManager, cancelPeripheralConnection peripheral: CBPeripheral) {}
    
    @available(iOS 13.0, *)
    func centralManager(_ central: CBCentralManager, registerForConnectionEventsWithOptions options: [CBConnectionEventMatchingOption: Any]?) {}
}
