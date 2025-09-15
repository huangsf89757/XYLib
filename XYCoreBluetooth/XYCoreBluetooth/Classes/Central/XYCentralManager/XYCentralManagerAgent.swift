//
//  XYCentralManagerAgent.swift
//  Pods
//
//  Created by hsf on 2025/9/10.
//

import Foundation
import CoreBluetooth
import XYExtension
import XYUtil
import XYLog

public final class XYCentralManagerAgent: NSObject {
    // MARK: log
    public static let logTag = "Ble.CM"
    /// 同一个外围设备广播日志打印间隔
    public static let logDiscoverInterval: TimeInterval = 5
    
    // MARK: shared
    public static let shared = XYCentralManagerAgent()
    private override init() {
        super.init()
        initCenterManager()
        addObservers()
    }
    /// 初始化
    /// CBCentralManagerOptionShowPowerAlertKey
    /// CBCentralManagerOptionRestoreIdentifierKey
    private func initCenterManager() {
        let logTag = [Self.logTag, "initCenterManager()"]
        let options: [String : Any] = [
            CBCentralManagerOptionShowPowerAlertKey: true,
            CBCentralManagerOptionRestoreIdentifierKey: Self.restoreKey,
        ]
        centralManager = CBCentralManager(delegate: self, queue: nil, options: options)
        XYLog.info(tag: logTag, process: .succ, content: "options=\(options.toJSONString() ?? "nil")")
    }
    deinit {
        removeObservers()
    }
    
    // MARK: ble
    /// 恢复Key
    public static let restoreKey = XYApp.key + "." + "BLE.RESTORE"
    /// 连接外设超时时间
    public var connectTimeout: TimeInterval = 30
    /// 自动恢复挂起前的状态
    public var autoRestore: Bool = true
    
    // MARK: centralManager
    /// 持有的中央设备
    public internal(set) var centralManager: CBCentralManager!
    
    // MARK: scan
    /* 开启扫描后，蓝牙开关开启则自动开始扫描 */
    public private(set) var scanServiceUUIDs: [CBUUID]?
    public private(set) var scanOptions: [String : Any]?
    
    // MARK: peripheral
    /// 已经扫描到的外围设备
    public internal(set) var discoveredPeripherals = [UUID: XYPeripheralAgent]()
    /// 当前持有的外围设备
    public internal(set) var lastPeripheralAgent: XYPeripheralAgent?
    /// 连接超时Task
    public internal(set) var connectTimeoutTaskMap = [UUID: DispatchWorkItem]()
    
    // MARK: plugin
    public var plugins = [XYCentralManagerPlugin]()
    
}

// MARK: - CBCentralManagerDelegate
extension XYCentralManagerAgent: CBCentralManagerDelegate {
    // delegate
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        var logTag = [Self.logTag, "didUpdateState()"]
        let state = central.state
        XYLog.info(tag: logTag, content: "central.state=\(state.info)")
        plugins.forEach { plugin in
            plugin.centralManagerDidUpdateState(central)
        }
        if state == .poweredOn, let scanServiceUUIDs = scanServiceUUIDs {
            logTag = [Self.logTag, "statrScan().stateUpdated"]
            _scanForPeripherals(withServices: scanServiceUUIDs, options: scanOptions, logTag: logTag)
        }
    }
}

// MARK: - restore
extension XYCentralManagerAgent {
    // delegate
    public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        let logTag = [Self.logTag, "willRestoreState()"]
        XYLog.info(tag: logTag, content: "dict=\(dict)")
        plugins.forEach { plugin in
            plugin.centralManager?(central, willRestoreState: dict)
        }
        guard autoRestore else { return }
        restoreScan(logTag: logTag, dict: dict)
        restoreConnect(logTag: logTag, dict: dict)
    }
    
    // 恢复扫描
    // 挂起前正在扫描的
    private func restoreScan(logTag: [String], dict: [String : Any]) {
        let logTag = [Self.logTag, "didConnectPeripheral().restore"]
        guard let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] else { return }
        peripherals.forEach { peripheral in
            _centralManager(centralManager, didConnect: peripheral, logTag: logTag)
        }
    }
    
    // 恢复连接
    // 挂起前正在连接/已连接的
    private func restoreConnect(logTag: [String], dict: [String : Any]) {
        let logTag = [Self.logTag, "statrScan().restore"]
        guard let serviceUUIDs = dict[CBCentralManagerRestoredStateScanServicesKey] as? [CBUUID] else { return }
        let options = dict[CBCentralManagerRestoredStateScanOptionsKey] as? [String: Any]
        _scanForPeripherals(withServices: serviceUUIDs, options: options, logTag: logTag)
    }
}

// MARK: - scan
extension XYCentralManagerAgent {
    /// 开启扫描
    /// CBCentralManagerScanOptionAllowDuplicatesKey
    /// CBCentralManagerScanOptionSolicitedServiceUUIDsKey
    public func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String : Any]? = nil) {
        let logTag = [Self.logTag, "statrScan()"]
        guard centralManager.state == .poweredOn else {
            XYLog.info(tag: logTag, process: .fail("central.state=\(centralManager.state.info)"))
            return
        }
        _scanForPeripherals(withServices: serviceUUIDs, options: options, logTag: logTag)
    }
    
    private func _scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String : Any]? = nil, logTag: [String]) {
        if let options = options {
            XYLog.info(tag: logTag, process: .begin, content: "options=\(options.toJSONString() ?? "nil")")
        } else {
            XYLog.info(tag: logTag, process: .begin)
        }
        centralManager.scanForPeripherals(withServices: serviceUUIDs, options: options)
        plugins.forEach { plugin in
            plugin.centralManager(centralManager, didTryScanForPeripherals: serviceUUIDs, options: options)
        }
        scanServiceUUIDs = serviceUUIDs
        scanOptions = options
    }
    
    /// 停止扫描
    public func stopScan() {
        let logTag = [Self.logTag, "stopScan()"]
        XYLog.info(tag: logTag, process: .begin)
        centralManager.stopScan()
        plugins.forEach { plugin in
            plugin.centralManagerDidTryStopScan(centralManager)
        }
        scanServiceUUIDs = nil
        scanOptions = nil
    }
}

extension XYCentralManagerAgent {
    // delegate
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let logTag = [Self.logTag, "didDiscoverPeripheral()"]
        let peripheralAgent = XYPeripheralAgent(peripheral: peripheral, advertisementData: advertisementData, RSSI: RSSI, discoverDate: Date())
        let uuid = peripheral.identifier
        let now = Date()
        if let logDate = discoveredPeripherals[uuid]?.logDate {
            let distance = logDate.distance(to: now)
            if distance > Self.logDiscoverInterval {
                XYLog.info(tag: logTag, content: "peripheral=\(peripheral.info)", "advData=\(advertisementData.toJSONString() ?? "nil")", "rssi=\(RSSI)")
                peripheralAgent.logDate = now
            }
        } else {
            peripheralAgent.logDate = now
        }
        discoveredPeripherals[uuid] = peripheralAgent
        plugins.forEach { plugin in
            plugin.centralManager?(central, didDiscover: peripheral, advertisementData: advertisementData, rssi: RSSI)
        }
    }
}

// MARK: - timeout
extension XYCentralManagerAgent {
    private func startConnectTimeoutTask(logTag: [String], for peripheral: CBPeripheral) {
        let uuid = peripheral.identifier
        let connectTimeoutTask = connectTimeoutTaskMap[uuid]
        connectTimeoutTask?.cancel()
        let task = DispatchWorkItem { [weak self] in
            XYLog.info(tag: logTag, process: .fail("TimeoutTask Handel (\(uuid))"))
            self?.plugins.forEach { plugin in
                guard let centralManager = self?.centralManager else { return }
                plugin.centralManager(centralManager, discoveredPeripheralsDidRemove: uuid)
            }
            let peripheralAgent = self?.discoveredPeripherals[uuid]
            guard let peripheral = peripheralAgent?.peripheral else { return }
            self?.plugins.forEach { plugin in
                guard let centralManager = self?.centralManager else { return }
                plugin.centralManager(centralManager, didConnectTimeout: peripheral)
            }
            self?.cancelPeripheralConnection(peripheral)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + connectTimeout, execute: task)
        connectTimeoutTaskMap[uuid] = task
        XYLog.info(tag: logTag, process: .doing, content: "TimeoutTask Start (\(uuid))")
    }
    private func cancelConnectTimeoutTask(logTag: [String], for peripheral: CBPeripheral) {
        let uuid = peripheral.identifier
        let connectTimeoutTask = connectTimeoutTaskMap[uuid]
        connectTimeoutTask?.cancel()
        connectTimeoutTaskMap[uuid] = nil
        XYLog.info(tag: logTag, process: .doing, content: "TimeoutTask Cancel (\(uuid))")
    }
}

// MARK: - connect
extension XYCentralManagerAgent {
    /// 连接外设
    /// CBConnectPeripheralOptionEnableAutoReconnect
    /// CBConnectPeripheralOptionEnableTransportBridgingKey
    /// CBConnectPeripheralOptionNotifyOnConnectionKey
    /// CBConnectPeripheralOptionNotifyOnDisconnectionKey
    /// CBConnectPeripheralOptionNotifyOnNotificationKey
    /// CBConnectPeripheralOptionRequiresANCS
    /// CBConnectPeripheralOptionStartDelayKey
    public func connect(_ peripheral: CBPeripheral, options: [String : Any]? = nil) {
        let logTag = [Self.logTag, "connectPeripheral()"]
        if let options = options {
            XYLog.info(tag: logTag, process: .begin, content: "options=\(options.toJSONString() ?? "nil")")
        } else {
            XYLog.info(tag: logTag, process: .begin)
        }
        guard centralManager.state == .poweredOn else {
            XYLog.info(tag: logTag, process: .fail("central.state=\(centralManager.state.info)"))
            return
        }
        // 连接前判断状态
        switch peripheral.state {
        case .disconnected:
            break
        case .connecting:
            XYLog.info(tag: logTag, process: .doing, content: "this peripheral is connecting")
            return
        case .connected:
            XYLog.info(tag: logTag, process: .succ, content: "this peripheral is already connected")
            return
        case .disconnecting:
            XYLog.info(tag: logTag, process: .fail("this peripheral is disconnecting"))
            return
        @unknown default:
            XYLog.info(tag: logTag, process: .fail("@unknown ERROR"))
            return
        }
        // 超时任务
        startConnectTimeoutTask(logTag: logTag, for: peripheral)
        // 连接
        let uuid = peripheral.identifier
        lastPeripheralAgent = discoveredPeripherals[uuid]
        plugins.forEach { plugin in
            plugin.centralManager(centralManager, discoveredPeripheralsDidAdd: uuid, peripheral: peripheral)
        }
        centralManager.connect(peripheral, options: options)
        // plugins
        plugins.forEach { plugin in
            plugin.centralManager(centralManager, didTryConnect: peripheral, options: options)
        }
    }
    
    /// 断开已连接的外设
    public func cancelPeripheralConnection(_ peripheral: CBPeripheral) {
        let logTag = [Self.logTag, "disconnectPeripheral()"]
        XYLog.info(tag: logTag, process: .begin)
        guard centralManager.state == .poweredOn else {
            XYLog.info(tag: logTag, process: .fail("central.state=\(centralManager.state.info)"))
            return
        }
        centralManager.cancelPeripheralConnection(peripheral)
        plugins.forEach { plugin in
            plugin.centralManager(centralManager, didTryCancelPeripheralConnection: peripheral)
        }
    }
}

extension XYCentralManagerAgent {
    // delegate
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        let logTag = [Self.logTag, "didConnectPeripheral()"]
        _centralManager(central, didConnect: peripheral, logTag: logTag)
    }
    
    private func _centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral, logTag: [String]) {
        XYLog.info(tag: logTag, content: "peripheral=\(peripheral.info)")
        cancelConnectTimeoutTask(logTag: logTag, for: peripheral)
        plugins.forEach { plugin in
            plugin.centralManager?(central, didConnect: peripheral)
        }
    }

    // delegate
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        let logTag = [Self.logTag, "didFailToConnectPeripheral()"]
        if let error = error {
            XYLog.info(tag: logTag, content: "peripheral=\(peripheral.info)", "error=\(error.info)")
        } else {
            XYLog.info(tag: logTag, content: "peripheral=\(peripheral.info)")
        }
        cancelConnectTimeoutTask(logTag: logTag, for: peripheral)
        plugins.forEach { plugin in
            plugin.centralManager?(central, didFailToConnect: peripheral, error: error)
        }
    }

    // delegate
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        let logTag = [Self.logTag, "didDisconnectPeripheral()"]
        if let error = error {
            XYLog.info(tag: logTag, content: "peripheral=\(peripheral.info)", "error=\(error.info)")
        } else {
            XYLog.info(tag: logTag, content: "peripheral=\(peripheral.info)")
        }
        plugins.forEach { plugin in
            plugin.centralManager?(central, didDisconnectPeripheral: peripheral, error: error)
        }
    }
    
    // delegate
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, timestamp: CFAbsoluteTime, isReconnecting: Bool, error: (any Error)?) {
        let logTag = [Self.logTag, "didDisconnectPeripheralWithReconnect()"]
        if let error = error {
            XYLog.info(tag: logTag, content: "peripheral=\(peripheral.info)", "timestamp=\(timestamp)", "isReconnecting=\(isReconnecting)", "error=\(error.info)")
        } else {
            XYLog.info(tag: logTag, content: "peripheral=\(peripheral.info)", "timestamp=\(timestamp)", "isReconnecting=\(isReconnecting)")
        }
        plugins.forEach { plugin in
            plugin.centralManager?(central, didDisconnectPeripheral: peripheral, timestamp: timestamp, isReconnecting: isReconnecting, error: error)
        }
    }
}

// MARK: - KVO
extension XYCentralManagerAgent {
    private func addObservers() {
        centralManager.addObserver(self, forKeyPath: "isScanning", options: .new, context: nil)
    }
    
    private func removeObservers() {
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
    }
}
