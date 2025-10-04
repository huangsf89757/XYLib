//
//  XYCentralManagerDelegate.swift
//  Pods
//
//  Created by hsf on 2025/9/10.
//

import Foundation
import CoreBluetooth

public protocol XYCentralManagerDelegate: CBCentralManagerDelegate {
    func centralManager(_ central: CBCentralManager, didTryScanForPeripherals serviceUUIDs: [CBUUID]?, options: [String : Any]?)
    func centralManagerDidTryStopScan(_ central: CBCentralManager)
    func centralManager(_ central: CBCentralManager, didTryConnect peripheral: CBPeripheral, options: [String : Any]?)
    func centralManager(_ central: CBCentralManager, didConnectTimeout peripheral: CBPeripheral)
    func centralManager(_ central: CBCentralManager, didTryCancelPeripheralConnection peripheral: CBPeripheral)
    
    func centralManager(_ central: CBCentralManager, didTryAddDiscoveredPeripheral uuid: UUID, peripheral: CBPeripheral)
    func centralManager(_ central: CBCentralManager, didTryRemoveDiscoveredPeripheral uuid: UUID)
}

public extension XYCentralManagerDelegate {
    func centralManager(_ central: CBCentralManager, didTryScanForPeripherals serviceUUIDs: [CBUUID]?, options: [String : Any]?) {}
    func centralManagerDidTryStopScan(_ central: CBCentralManager) {}
    func centralManager(_ central: CBCentralManager, didTryConnect peripheral: CBPeripheral, options: [String : Any]?) {}
    func centralManager(_ central: CBCentralManager, didConnectTimeout peripheral: CBPeripheral) {}
    func centralManager(_ central: CBCentralManager, didTryCancelPeripheralConnection peripheral: CBPeripheral) {}
    
    func centralManager(_ central: CBCentralManager, didTryAddDiscoveredPeripheral uuid: UUID, peripheral: CBPeripheral) {}
    func centralManager(_ central: CBCentralManager, didTryRemoveDiscoveredPeripheral uuid: UUID) {}
}