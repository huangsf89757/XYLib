//
//  XYPeripheralManager.swift
//  XYCoreBluetooth
//
//  Created by hsf on 2025/10/16.
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

// MARK: - XYPeripheralManager
/// 外设管理器封装，统一外设发布、服务管理、传输与回调日志
open class XYPeripheralManager: NSObject {
    // MARK: var
    /// 系统外设管理器
    public private(set) var peripheralManager: CBPeripheralManager!
    /// 代理
    public weak var delegate: (any XYPeripheralManagerDelegate)?

    /// 是否正在广播
    open var isAdvertising: Bool { peripheralManager.isAdvertising }

    // MARK: init
    /// 初始化
    /// - Parameters:
    ///   - delegate: 代理
    ///   - queue: 队列
    ///   - options: 选项
    public init(delegate: (any XYPeripheralManagerDelegate)?, queue: dispatch_queue_t? = nil, options: [String : Any]? = nil) {
        super.init()
        peripheralManager = CBPeripheralManager(delegate: nil, queue: queue, options: options)
        peripheralManager.delegate = self
        self.delegate = delegate
        XYBleLog.debug(params:[
            "delegate": delegate?.description ?? "nil",
            "queue": queue?.description ?? "nil",
            "options": options?.toJSONString() ?? "nil",
        ])
    }

    // MARK: advertising
    /// 开始广播
    open func startAdvertising(_ advertisementData: [String : Any]?) {
        peripheralManager.startAdvertising(advertisementData)
        XYBleLog.debug(params:[
            "advertisementData": advertisementData?.toJSONString() ?? "nil",
        ])
        self.delegate?.peripheralManager(peripheralManager, startAdvertising: advertisementData)
    }

    /// 停止广播
    open func stopAdvertising() {
        peripheralManager.stopAdvertising()
        XYBleLog.debug()
        self.delegate?.peripheralManager(peripheralManager, stopAdvertising: ())
    }

    // MARK: services
    /// 添加服务
    open func add(_ service: CBMutableService) {
        peripheralManager.add(service)
        XYBleLog.debug(params:[
            "service": service.info,
        ])
        self.delegate?.peripheralManager(peripheralManager, add: service)
    }

    /// 移除服务
    open func remove(_ service: CBMutableService) {
        peripheralManager.remove(service)
        XYBleLog.debug(params:[
            "service": service.info,
        ])
        self.delegate?.peripheralManager(peripheralManager, remove: service)
    }

    /// 移除所有服务
    open func removeAllServices() {
        peripheralManager.removeAllServices()
        XYBleLog.debug()
        self.delegate?.peripheralManager(peripheralManager, removeAllServices: ())
    }

    // MARK: connection latency
    /// 设置期望连接时延
    open func setDesiredConnectionLatency(_ latency: CBPeripheralManagerConnectionLatency, for central: CBCentral) {
        peripheralManager.setDesiredConnectionLatency(latency, for: central)
        XYBleLog.debug(params:[
            "latency": String(describing: latency),
            "central": central.info,
        ])
        self.delegate?.peripheralManager(peripheralManager, setDesiredConnectionLatency: latency, for: central)
    }

    // MARK: I/O
    /// 更新特征值到订阅者
    @discardableResult
    open func updateValue(_ value: Data, for characteristic: CBMutableCharacteristic, onSubscribedCentrals centrals: [CBCentral]?) -> Bool {
        let ok = peripheralManager.updateValue(value, for: characteristic, onSubscribedCentrals: centrals)
        XYBleLog.debug(params:[
            "value.count": String(value.count),
            "characteristic": characteristic.info,
            "centrals.count": String(centrals?.count ?? 0),
        ], returns: String(ok))
        self.delegate?.peripheralManager(peripheralManager, updateValue: value, for: characteristic, onSubscribedCentrals: centrals, returns: ok)
        return ok
    }

    /// 响应读写请求
    open func respond(to request: CBATTRequest, withResult result: CBATTError.Code) {
        peripheralManager.respond(to: request, withResult: result)
        XYBleLog.debug(params:[
            "request": request.info,
            "result": String(describing: result),
        ])
        self.delegate?.peripheralManager(peripheralManager, respondTo: request, withResult: result)
    }

    // MARK: L2CAP
    @available(iOS 11.0, *)
    open func publishL2CAPChannel(withEncryption encryptionRequired: Bool) {
        peripheralManager.publishL2CAPChannel(withEncryption: encryptionRequired)
        XYBleLog.debug(params:[
            "encryptionRequired": String(encryptionRequired),
        ])
        self.delegate?.peripheralManager(peripheralManager, publishL2CAPChannelWithEncryption: encryptionRequired)
    }

    @available(iOS 11.0, *)
    open func unpublishL2CAPChannel(_ PSM: CBL2CAPPSM) {
        peripheralManager.unpublishL2CAPChannel(PSM)
        XYBleLog.debug(params:[
            "PSM": String(PSM),
        ])
        self.delegate?.peripheralManager(peripheralManager, unpublishL2CAPChannel: PSM)
    }
}

// MARK: - CBPeripheralManagerDelegate
extension XYPeripheralManager: CBPeripheralManagerDelegate {
    public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        self.delegate?.peripheralManagerDidUpdateState(peripheral)
        XYBleLog.debug(params:[
            "peripheralManager": peripheral.info,
        ])
    }

    public func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String : Any]) {
        self.delegate?.peripheralManager?(peripheral, willRestoreState: dict)
        XYBleLog.debug(params:[
            "peripheralManager": peripheral.info,
            "dict": dict.toJSONString() ?? "[:]",
        ])
    }

    public func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: (any Error)?) {
        self.delegate?.peripheralManager?(peripheral, didAdd: service, error: error)
        XYBleLog.debug(params:[
            "peripheralManager": peripheral.info,
            "service": service.info,
            "error": error?.localizedDescription ?? "nil",
        ])
    }

    public func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        self.delegate?.peripheralManager?(peripheral, central: central, didSubscribeTo: characteristic)
        XYBleLog.debug(params:[
            "peripheralManager": peripheral.info,
            "central": central.info,
            "characteristic": characteristic.info,
        ])
    }

    public func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        self.delegate?.peripheralManager?(peripheral, central: central, didUnsubscribeFrom: characteristic)
        XYBleLog.debug(params:[
            "peripheralManager": peripheral.info,
            "central": central.info,
            "characteristic": characteristic.info,
        ])
    }

    public func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        self.delegate?.peripheralManagerIsReady?(toUpdateSubscribers: peripheral)
        XYBleLog.debug(params:[
            "peripheralManager": peripheral.info,
        ])
    }

    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        self.delegate?.peripheralManager?(peripheral, didReceiveRead: request)
        XYBleLog.debug(params:[
            "peripheralManager": peripheral.info,
            "request": request.info,
        ])
    }

    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        self.delegate?.peripheralManager?(peripheral, didReceiveWrite: requests)
        XYBleLog.debug(params:[
            "peripheralManager": peripheral.info,
            "requests.count": String(requests.count),
        ])
    }

    @available(iOS 11.0, *)
    public func peripheralManager(_ peripheral: CBPeripheralManager, didPublishL2CAPChannel PSM: CBL2CAPPSM, error: (any Error)?) {
        self.delegate?.peripheralManager?(peripheral, didPublishL2CAPChannel: PSM, error: error)
        XYBleLog.debug(params:[
            "peripheralManager": peripheral.info,
            "PSM": String(PSM),
            "error": error?.localizedDescription ?? "nil",
        ])
    }

    @available(iOS 11.0, *)
    public func peripheralManager(_ peripheral: CBPeripheralManager, didUnpublishL2CAPChannel PSM: CBL2CAPPSM, error: (any Error)?) {
        self.delegate?.peripheralManager?(peripheral, didUnpublishL2CAPChannel: PSM, error: error)
        XYBleLog.debug(params:[
            "peripheralManager": peripheral.info,
            "PSM": String(PSM),
            "error": error?.localizedDescription ?? "nil",
        ])
    }

    @available(iOS 11.0, *)
    public func peripheralManager(_ peripheral: CBPeripheralManager, didOpen channel: CBL2CAPChannel?, error: (any Error)?) {
        self.delegate?.peripheralManager?(peripheral, didOpen: channel, error: error)
        XYBleLog.debug(params:[
            "peripheralManager": peripheral.info,
            "channel": channel?.description ?? "nil",
            "error": error?.localizedDescription ?? "nil",
        ])
    }
}


