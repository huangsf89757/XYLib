//
//  XYCMConnectCmd.swift
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


// MARK: - XYCMConnectCmd
/// 【CMD】连接外围设备
/// - 执行`run()`开始连接外围设备
/// - 在`timeout`秒内未连接外围设备成功时，则触发超时
/// - 间隔`retryDelay`秒后重试
/// - 最多重试`maxRetries`次
/// - 执行`cancel()`取消连接外围设备
public class XYCMConnectCmd: XYCentralManagerCmd<CBPeripheral> {
    // MARK: var
    public let peripheral: CBPeripheral
    public let options: [String: Any]?
    
    fileprivate var continuation: CheckedContinuation<ResultType, any Error>?
    fileprivate var discoveredPeripherals = Set<CBPeripheral>()
    
    private lazy var delegate: XYCMConnectCmdDelegate = {
        let delegate = XYCMConnectCmdDelegate()
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
        peripheral: CBPeripheral,
        options: [String: Any]?
    ) {
        self.peripheral = peripheral
        self.options = options
        super.init(id: id, timeout: timeout, maxRetries: maxRetries, retryDelay: retryDelay, centralManagerWrapper: centralManagerWrapper)
        self.logTag = ["XYCmd", "Ble", "CM", "Connect"]
    }
    
    // MARK: run
    open override func run() async throws -> ResultType {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
        }
    }
    
    // MARK: hook func
    open override func willExecute() {
        super.willExecute()
        centralManagerWrapper.delegate = self.delegate
        centralManagerWrapper.connect(peripheral, options: options)
    }
    open override func didTimeout() {
        super.didTimeout()
        centralManagerWrapper.cancelPeripheralConnection(peripheral)
        centralManagerWrapper.delegate = oldDelegate
    }
    open override func didCancelExecute() {
        super.didCancelExecute()
        centralManagerWrapper.cancelPeripheralConnection(peripheral)
        centralManagerWrapper.delegate = oldDelegate
    }
}

// MARK: - XYCMConnectCmdDelegate
class XYCMConnectCmdDelegate: NSObject {
    weak var cmd: XYCMConnectCmd?
}

// MARK: - XYCentralManagerWrapperDelegate
extension XYCMConnectCmdDelegate: XYCentralManagerWrapperDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard central.state == .poweredOn else {
            return
        }
        guard let cmd = cmd else { return }
        guard cmd.state == .executing else {
            return
        }
        cmd.centralManagerWrapper.connect(cmd.peripheral, options: cmd.options)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard let cmd = cmd else { return }
        cmd.continuation?.resume(returning: peripheral)
    }
   
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) async {
        guard let cmd = cmd else { return }
        do {
            await try cmd.retry()
        } catch let e {
            let err = XYCMConnectCmd.normalizeError(error)
            cmd.continuation?.resume(throwing: err)
        }
    }
}


/*
 【使用示例】
 ```
 let connectCmd = XYCMConnectCmd(
     centralManagerWrapper: yourCentralManagerWrapper,
     peripheral: targetPeripheral,
     options: nil
 )
 Task {
     do {
         let connectedPeripheral = try await connectCmd.execute()
         print("✅ Connected to: (connectedPeripheral.name ?? "Unknown")")
     } catch {
         print("❌ Connect failed: $error)")
     }
 }
 ```
 */
