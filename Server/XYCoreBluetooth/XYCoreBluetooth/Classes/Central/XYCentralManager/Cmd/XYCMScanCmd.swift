//
//  XYCMScanCmd.swift
//  CocoaLumberjack
//
//  Created by hsf on 2025/12/22.
//

// MARK: - Import
// System
import Foundation
import CoreBluetooth
// Basic
import XYExtension
// Server
import XYLog
// Tool
import XYUtil
import XYCmd
// Business
// Third


// MARK: - XYCMScanCmd
/// 【CMD】扫描
/// - 执行`run()`开始扫描
/// - 在`timeout`内未扫描到符合`condition`条件的外围设备时，则触发超时
/// - 间隔`retryDelay`秒后重试
/// - 最多重试`maxRetries`次
/// - 执行`cancel()`停止扫描
public class XYCMScanCmd: XYCentralManagerCmd<AsyncThrowingStream<CBPeripheral, Error>> {
    // MARK: var
    public let serviceUUIDs: [CBUUID]?
    public let options: [String: Any]?
//    public let condition: [String: Any]?
    
    fileprivate var continuation: AsyncThrowingStream<CBPeripheral, Error>.Continuation?
    
    private var discoveredPeripherals = Set<CBPeripheral>()
    
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
        options: [String: Any]?
    ) {
        self.serviceUUIDs = serviceUUIDs
        self.options = options
        super.init(id: id, timeout: timeout, maxRetries: maxRetries, retryDelay: retryDelay, centralManagerWrapper: centralManagerWrapper)
        self.logTag = "XYCmd.Ble.CM.Scan"
    }
    
    // MARK: run
    open override func run() async throws -> AsyncThrowingStream<CBPeripheral, Error> {
        return AsyncThrowingStream { [weak self] continuation in
            guard let self = self else { return }
            self.continuation = continuation
            self.centralManagerWrapper.delegate = self.delegate
            self.centralManagerWrapper.scanForPeripherals(withServices: self.serviceUUIDs, options: self.options)
        }
    }
    
    // MARK: cancel
    open override func cancel() {
        super.cancel()
        centralManagerWrapper.stopScan()
        centralManagerWrapper.delegate = oldDelegate
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
        cmd.continuation?.yield(peripheral)
    }
}
