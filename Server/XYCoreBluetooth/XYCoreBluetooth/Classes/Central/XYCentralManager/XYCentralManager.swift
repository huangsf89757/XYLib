//
//  XYCentralManager.swift
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

// MARK: - XYCentralManager
open class XYCentralManager: NSObject {
    // MARK: var
    public private(set) var centralManager: CBCentralManager!
    weak public var delegate: (any XYCentralManagerDelegate)?
    
    @available(iOS 9.0, *)
    public var isScanning: Bool {
        return centralManager.isScanning
    }
    
    // MARK: init
    public init(delegate: (any XYCentralManagerDelegate)?, queue: dispatch_queue_t?, options: [String : Any]? = nil) {
        super.init()
        centralManager = CBCentralManager(delegate: delegate, queue: queue, options: options)
        centralManager.delegate = self
        self.delegate = delegate
        debug(params:[
            "delegate": delegate?.description ?? "nil",
            "queue": queue?.description ?? "nil",
            "options": options?.toJSONString() ?? "nil",
        ])
    }
    
    @available(iOS 7.0, *)
    open func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [CBPeripheral] {
        let peripherals = centralManager.retrievePeripherals(withIdentifiers: identifiers)
        debug(params:[
            "identifiers": identifiers.map{ $0.uuidString }.toJSONString() ?? "[]",
        ], returns: peripherals.map{ $0.info }.toJSONString())
        self.delegate?.centralManager(centralManager, retrievePeripheralsWithIdentifiers: identifiers, returns: peripherals)
        return peripherals
    }

    @available(iOS 7.0, *)
    open func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> [CBPeripheral] {
        let peripherals = centralManager.retrieveConnectedPeripherals(withServices: serviceUUIDs)
        debug(params:[
            "serviceUUIDs": serviceUUIDs.map{ $0.uuidString }.toJSONString() ?? "[]",
        ], returns: peripherals.map{ $0.info }.toJSONString())
        self.delegate?.centralManager(centralManager, retrieveConnectedPeripheralsWithServices: serviceUUIDs, returns: peripherals)
        return peripherals
    }
    
    open func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String : Any]? = nil) {
        centralManager.scanForPeripherals(withServices: serviceUUIDs, options: options)
        debug(params:[
            "serviceUUIDs": serviceUUIDs?.map{ $0.uuidString }.toJSONString() ?? "nil",
            "options": options?.toJSONString() ?? "nil",
        ])
        self.delegate?.centralManager(centralManager, scanForPeripheralsWithServices: serviceUUIDs, options: options)
    }
    
    open func stopScan() {
        centralManager.stopScan()
        debug()
        self.delegate?.centralManager(centralManager, stopScan: ())
    }
    
    open func connect(_ peripheral: CBPeripheral, options: [String : Any]? = nil) {
        centralManager.connect(peripheral, options: options)
        debug(params:[
            "peripheral": peripheral.info,
            "options": options?.toJSONString() ?? "nil",
        ])
        self.delegate?.centralManager(centralManager, connect: peripheral, options: options)
    }
    
    open func cancelPeripheralConnection(_ peripheral: CBPeripheral) {
        centralManager.cancelPeripheralConnection(peripheral)
        debug(params:[
            "peripheral": peripheral.info,
        ])
        self.delegate?.centralManager(centralManager, cancelPeripheralConnection: peripheral)
    }

    @available(iOS 13.0, *)
    open func registerForConnectionEvents(options: [CBConnectionEventMatchingOption : Any]? = nil) {
        centralManager.registerForConnectionEvents(options: options)
        debug(params:[
            "options": options?.toJSONString() ?? "nil",
        ])
        self.delegate?.centralManager(centralManager, registerForConnectionEventsWithOptions: options)
    }
}

// MARK: - CBCentralManagerDelegate
extension XYCentralManager: CBCentralManagerDelegate {
    
    @available(iOS 5.0, *)
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        self.delegate?.centralManagerDidUpdateState(central)
        debug(params:[
            "central": central.info,
        ])
    }

    @available(iOS 5.0, *)
    public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        self.delegate?.centralManager?(central, willRestoreState: dict)
        debug(params:[
            "central": central.info,
            "dict": dict.toJSONString() ?? "[:]",
        ])
    }

    @available(iOS 5.0, *)
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        self.delegate?.centralManager?(central, didDiscover: peripheral, advertisementData: advertisementData, rssi: RSSI)
        debug(params:[
            "central": central.info,
            "peripheral": peripheral.info,
            "advertisementData": advertisementData.toJSONString() ?? "[:]",
            "RSSI": RSSI.stringValue,
        ])
    }

    @available(iOS 5.0, *)
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.delegate?.centralManager?(central, didConnect: peripheral)
        debug(params:[
            "central": central.info,
            "peripheral": peripheral.info,
        ])
    }

    @available(iOS 5.0, *)
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
        self.delegate?.centralManager?(central, didFailToConnect: peripheral, error: error)
        debug(params:[
            "central": central.info,
            "peripheral": peripheral.info,
            "error": error?.localizedDescription ?? "nil",
        ])
    }
    
    @available(iOS 5.0, *)
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
        self.delegate?.centralManager?(central, didDisconnectPeripheral: peripheral, error: error)
        debug(params:[
            "central": central.info,
            "peripheral": peripheral.info,
            "error": error?.localizedDescription ?? "nil",
        ])
    }

    @available(iOS 5.0, *)
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, timestamp: CFAbsoluteTime, isReconnecting: Bool, error: (any Error)?) {
        self.delegate?.centralManager?(central, didDisconnectPeripheral: peripheral, timestamp: timestamp, isReconnecting: isReconnecting, error: error)
        debug(params:[
            "central": central.info,
            "peripheral": peripheral.info,
            "timestamp": String(format: "%.2f", timestamp),
            "isReconnecting": String(isReconnecting),
            "error": error?.localizedDescription ?? "nil",
        ])
    }

    @available(iOS 13.0, *)
    public func centralManager(_ central: CBCentralManager, connectionEventDidOccur event: CBConnectionEvent, for peripheral: CBPeripheral) {
        self.delegate?.centralManager?(central, connectionEventDidOccur: event, for: peripheral)
        debug(params:[
            "central": central.info,
            "event": String(describing: event),
            "peripheral": peripheral.info,
        ])
    }

    @available(iOS 13.0, *)
    public func centralManager(_ central: CBCentralManager, didUpdateANCSAuthorizationFor peripheral: CBPeripheral) {
        self.delegate?.centralManager?(central, didUpdateANCSAuthorizationFor: peripheral)
        debug(params:[
            "central": central.info,
            "peripheral": peripheral.info,
        ])
    }
}

// MARK: - Log
extension XYCentralManager {
    public static let tag = "XY.BLE"
    private func debug(file: String = #file,
                       function: String = #function,
                       line: Int = #line,
                       id: String? = nil,
                       process: XYLogProcess? = nil,
                       params: [String: String]? = nil,
                       returns: String? = nil) {
        var content_params = "void"
        if let params {
            content_params = "\n" + params.map { (key, value) in
                "- \(key) = \(value)"
            }.joined(separator: "\n")
        }
        var content_returns = "void"
        if let returns {
            content_returns = "\n" + "> \(returns)"
        }
        let content = """
            \(function)
            params: \(content_params)
            return: \(content_returns)
            """
        XYLog.debug(file: file,
                    function: function,
                    line: line,
                    id: id,
                    tag: [Self.tag],
                    process: process,
                    content: content)
    }
    
    
}
