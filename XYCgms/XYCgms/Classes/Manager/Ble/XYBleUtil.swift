//
//  XYBleUtil.swift
//  XYCgms
//
//  Created by hsf on 2025/8/28.
//

import Foundation
import CoreBluetooth
import XYExtension
import XYUtil
import XYLog

// MARK: - KVO
extension XYBleManager {
    internal func addObservers() {
        centralManager.addObserver(self, forKeyPath: "isScanning", options: .new, context: nil)
    }
    
    internal func removeObservers() {
        centralManager.removeObserver(self, forKeyPath: "isScanning")
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        let logTag = [Self.logTag, "KVO"]
        if let centralManager = object as? CBCentralManager, centralManager == self.centralManager {
            if keyPath == "isScanning", let isScanning = change?[.newKey] as? Bool {
                XYLog.info(tag: logTag, content: "central.isScanning=\(isScanning)")
                return
            }
            return
        }
//        if let peripheral = object as? CBPeripheral,
//           let curPeripheral = curPeripheral,
//           peripheral.identifier.uuidString == curPeripheral.identifier.uuidString {
//            if keyPath == "state",
//               let rawValue = change?[.newKey] as? Int,
//               let state = CBPeripheralState(rawValue: rawValue) {
//                MTLogger.log(tag: "CB<1>", "peripheral.state=\(state.msg)")
//                self.isConnecting = state == .connected
//                return
//            }
//            return
//        }
    }
}
