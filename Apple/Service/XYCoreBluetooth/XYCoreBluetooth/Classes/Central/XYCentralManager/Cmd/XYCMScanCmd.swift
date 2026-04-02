//
//  XYCMScanCmd.swift
//  XYCoreBluetooth
//
//  Created by hsf on 2025/12/22.
//

// MARK: - Import
// System
import Foundation
import CoreBluetooth
// Basic
import XYExtension
// Service
import XYLog
// Tool
import XYUtil
import XYCmd
// Business
// Third


// MARK: - XYCMScanCmd
/// 【CMD】扫描外围设备
/// - 执行`run()`开始扫描外围设备
/// - 在`timeout`秒内未扫描到符合`condition`条件的外围设备时，则触发超时
/// - 间隔`retryDelay`秒后重试
/// - 最多重试`maxRetries`次
/// - 执行`cancel()`停止扫描外围设备
public class XYCMScanCmd: XYCentralManagerCmd<AsyncThrowingStream<CBPeripheral, Error>> {
    // MARK: var
    public let serviceUUIDs: [CBUUID]?
    public let options: [String: Any]?
    public let condition: ((CBPeripheral, [String: Any], NSNumber) -> Bool)?
    
    fileprivate var continuation: ResultType.Continuation?
    fileprivate var discoveredPeripherals = Set<CBPeripheral>()
    
    private lazy var delegate: XYCMScanCmdDelegate = {
        let delegate = XYCMScanCmdDelegate()
        delegate.cmd = self
        return delegate
    }()
    
    // MARK: life cycle
    public init(
        id: String = UUID().uuidString,
        timeout: TimeInterval = 30,
        maxRetries: Int? = 2,
        retryDelay: TimeInterval? = 1.0,
        centralManagerWrapper: XYCentralManagerWrapper,
        serviceUUIDs: [CBUUID]? = nil,
        options: [String: Any]?,
        condition: ((CBPeripheral, [String: Any], NSNumber) -> Bool)? = nil
    ) {
        self.serviceUUIDs = serviceUUIDs
        self.options = options
        self.condition = condition
        super.init(id: id, timeout: timeout, maxRetries: maxRetries, retryDelay: retryDelay, centralManagerWrapper: centralManagerWrapper)
        self.logTag = ["XYCmd", "Ble", "CM", "Scan"].joined(separator: ".")
    }
    
    // MARK: run
    open override func run() async throws -> ResultType {
        return AsyncThrowingStream { [weak self] continuation in
            guard let self = self else { return }
            self.continuation = continuation
        }
    }
    
    // MARK: hook func
    open override func willExecute() {
        super.willExecute()
        self.centralManagerWrapper.delegate = self.delegate
        self.centralManagerWrapper.scanForPeripherals(withServices: self.serviceUUIDs, options: self.options)
    }
    open override func didTimeout() {
        super.didTimeout()
        centralManagerWrapper.stopScan()
        centralManagerWrapper.delegate = oldDelegate
        continuation = nil
    }
    open override func didCancelExecute() {
        super.didCancelExecute()
        centralManagerWrapper.stopScan()
        centralManagerWrapper.delegate = oldDelegate
        continuation = nil
    }
}

// MARK: - XYCMScanCmdDelegate
class XYCMScanCmdDelegate: NSObject {
    weak var cmd: XYCMScanCmd?
}

// MARK: - XYCentralManagerWrapperDelegate
extension XYCMScanCmdDelegate: XYCentralManagerWrapperDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard central.state == .poweredOn else {
            return
        }
        guard let cmd = cmd else { return }
        guard cmd.state == .executing else {
            return
        }
        cmd.centralManagerWrapper.scanForPeripherals(withServices: cmd.serviceUUIDs, options: cmd.options)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard let cmd = cmd else { return }
        if !cmd.discoveredPeripherals.contains(peripheral) {
            cmd.discoveredPeripherals.insert(peripheral)
        }
        let shouldYield: Bool
        if let condition = cmd.condition {
            shouldYield = condition(peripheral, advertisementData, RSSI)
        } else {
            shouldYield = true
        }
        if shouldYield {
            cmd.continuation?.yield(peripheral)
        }
    }
}


/*
 【使用示例】
 ```
 let condition: (CBPeripheral, [String: Any], NSNumber) -> Bool = { peripheral, advData, rssi in
     // 示例：设备名包含 "MyDevice" 且 RSSI > -70
     guard let name = peripheral.name, name.contains("MyDevice") else { return false }
     return rssi.intValue > -70
 }
 let scanCmd = XYCMScanCmd(
     centralManagerWrapper: yourWrapper,
     serviceUUIDs: nil,
     options: nil,
     condition: condition
 )
 Task {
     do {
         for try await peripheral in try await scanCmd.run() {
             print("Found matching peripheral: \(peripheral.name ?? "Unknown")")
             // 可在此处 stop scan 或继续监听
         }
     } catch {
        print("Scan failed: $error)")
     }
 }
 ```
 */
