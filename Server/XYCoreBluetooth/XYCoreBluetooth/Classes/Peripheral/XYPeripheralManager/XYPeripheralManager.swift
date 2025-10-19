//
//  XYPeripheralManager.swift
//  XYCoreBluetooth
//
//  Created by hsf on 2025/10/16.
//

#if os(iOS) || os(macOS) || os(tvOS)

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
/// 外设管理器封装，统一外设发布、服务管理、传输与回调日志，提供蓝牙外设广播、服务管理等功能
open class XYPeripheralManager: NSObject {
    // MARK: Property
    /// CBPeripheralManager实例，用于管理蓝牙外设
    public private(set) var peripheralManager: CBPeripheralManager!
    /// 代理对象，用于处理蓝牙事件回调
    public weak var delegate: (any XYPeripheralManagerDelegate)?
    
    /// 授权状态
    @available(iOS 13.1, *)
    open class var authorization: CBManagerAuthorization {
        return CBPeripheralManager.authorization
    }
    
    /// 蓝牙状态
    open var state: CBManagerState {
        return peripheralManager.state
    }
    
    /// 是否正在广播
    open var isAdvertising: Bool { peripheralManager.isAdvertising }

    // MARK: Life Cycle
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

    // MARK: Advertising
    /// 开始广播
    /// - Parameter advertisementData: 广播数据，包含设备名称、服务UUID等信息
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

    // MARK: Service
    /// 添加服务
    /// - Parameter service: 要添加的可变服务对象
    open func add(_ service: CBMutableService) {
        peripheralManager.add(service)
        XYBleLog.debug(params:[
            "service": service.info,
        ])
        self.delegate?.peripheralManager(peripheralManager, add: service)
    }

    /// 移除服务
    /// - Parameter service: 要移除的可变服务对象
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

    // MARK: Connection Latency
    /// 设置期望连接时延
    /// - Parameters:
    ///   - latency: 期望的连接时延值
    ///   - central: 中心设备对象
    open func setDesiredConnectionLatency(_ latency: CBPeripheralManagerConnectionLatency, for central: CBCentral) {
        peripheralManager.setDesiredConnectionLatency(latency, for: central)
        XYBleLog.debug(params:[
            "latency": String(describing: latency),
            "central": central.info,
        ])
        self.delegate?.peripheralManager(peripheralManager, setDesiredConnectionLatency: latency, for: central)
    }

    // MARK: I/O Operations
    /// 更新特征值到订阅者
    /// - Parameters:
    ///   - value: 要更新的数据
    ///   - characteristic: 要更新的特征对象
    ///   - centrals: 订阅的中心设备数组，为nil时发送给所有订阅者
    /// - Returns: 更新是否成功
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
    /// - Parameters:
    ///   - request: 要响应的读写请求
    ///   - result: 响应结果
    open func respond(to request: CBATTRequest, withResult result: CBATTError.Code) {
        peripheralManager.respond(to: request, withResult: result)
        XYBleLog.debug(params:[
            "request": request.info,
            "result": String(describing: result),
        ])
        self.delegate?.peripheralManager(peripheralManager, respondTo: request, withResult: result)
    }

    // MARK: L2CAP Channels
    /// 发布L2CAP通道（iOS 11.0+）
    /// - Parameter encryptionRequired: 是否需要加密
    @available(iOS 11.0, *)
    open func publishL2CAPChannel(withEncryption encryptionRequired: Bool) {
        peripheralManager.publishL2CAPChannel(withEncryption: encryptionRequired)
        XYBleLog.debug(params:[
            "encryptionRequired": String(encryptionRequired),
        ])
        self.delegate?.peripheralManager(peripheralManager, publishL2CAPChannelWithEncryption: encryptionRequired)
    }

    /// 取消发布L2CAP通道（iOS 11.0+）
    /// - Parameter PSM: L2CAP通道PSM值
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
/// CBPeripheralManager代理方法实现，转发事件到自定义代理
extension XYPeripheralManager: CBPeripheralManagerDelegate {
    /// 外设管理器状态更新回调
    /// - Parameter peripheral: 外设管理器实例
    public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        self.delegate?.peripheralManagerDidUpdateState(peripheral)
        XYBleLog.debug(params:[
            "peripheralManager": peripheral.info,
        ])
    }

    /// 外设管理器状态恢复回调
    /// - Parameters:
    ///   - peripheral: 外设管理器实例
    ///   - dict: 状态字典
    public func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String : Any]) {
        self.delegate?.peripheralManager?(peripheral, willRestoreState: dict)
        XYBleLog.debug(params:[
            "peripheralManager": peripheral.info,
            "dict": dict.toJSONString() ?? "[:]",
        ])
    }

    /// 添加服务完成回调
    /// - Parameters:
    ///   - peripheral: 外设管理器实例
    ///   - service: 添加的服务
    ///   - error: 错误信息
    public func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: (any Error)?) {
        self.delegate?.peripheralManager?(peripheral, didAdd: service, error: error)
        XYBleLog.debug(params:[
            "peripheralManager": peripheral.info,
            "service": service.info,
            "error": error?.localizedDescription ?? "nil",
        ])
    }

    /// 中心设备订阅特征回调
    /// - Parameters:
    ///   - peripheral: 外设管理器实例
    ///   - central: 订阅的中心设备
    ///   - characteristic: 被订阅的特征
    public func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        self.delegate?.peripheralManager?(peripheral, central: central, didSubscribeTo: characteristic)
        XYBleLog.debug(params:[
            "peripheralManager": peripheral.info,
            "central": central.info,
            "characteristic": characteristic.info,
        ])
    }

    /// 中心设备取消订阅特征回调
    /// - Parameters:
    ///   - peripheral: 外设管理器实例
    ///   - central: 取消订阅的中心设备
    ///   - characteristic: 被取消订阅的特征
    public func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        self.delegate?.peripheralManager?(peripheral, central: central, didUnsubscribeFrom: characteristic)
        XYBleLog.debug(params:[
            "peripheralManager": peripheral.info,
            "central": central.info,
            "characteristic": characteristic.info,
        ])
    }

    /// 外设管理器准备好更新订阅者回调
    /// - Parameter peripheral: 外设管理器实例
    public func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        self.delegate?.peripheralManagerIsReady?(toUpdateSubscribers: peripheral)
        XYBleLog.debug(params:[
            "peripheralManager": peripheral.info,
        ])
    }

    /// 接收到读请求回调
    /// - Parameters:
    ///   - peripheral: 外设管理器实例
    ///   - request: 读请求
    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        self.delegate?.peripheralManager?(peripheral, didReceiveRead: request)
        XYBleLog.debug(params:[
            "peripheralManager": peripheral.info,
            "request": request.info,
        ])
    }

    /// 接收到写请求回调
    /// - Parameters:
    ///   - peripheral: 外设管理器实例
    ///   - requests: 写请求数组
    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        self.delegate?.peripheralManager?(peripheral, didReceiveWrite: requests)
        XYBleLog.debug(params:[
            "peripheralManager": peripheral.info,
            "requests.count": String(requests.count),
        ])
    }

    /// 发布L2CAP通道完成回调（iOS 11.0+）
    /// - Parameters:
    ///   - peripheral: 外设管理器实例
    ///   - PSM: L2CAP通道PSM值
    ///   - error: 错误信息
    @available(iOS 11.0, *)
    public func peripheralManager(_ peripheral: CBPeripheralManager, didPublishL2CAPChannel PSM: CBL2CAPPSM, error: (any Error)?) {
        self.delegate?.peripheralManager?(peripheral, didPublishL2CAPChannel: PSM, error: error)
        XYBleLog.debug(params:[
            "peripheralManager": peripheral.info,
            "PSM": String(PSM),
            "error": error?.localizedDescription ?? "nil",
        ])
    }

    /// 取消发布L2CAP通道完成回调（iOS 11.0+）
    /// - Parameters:
    ///   - peripheral: 外设管理器实例
    ///   - PSM: L2CAP通道PSM值
    ///   - error: 错误信息
    @available(iOS 11.0, *)
    public func peripheralManager(_ peripheral: CBPeripheralManager, didUnpublishL2CAPChannel PSM: CBL2CAPPSM, error: (any Error)?) {
        self.delegate?.peripheralManager?(peripheral, didUnpublishL2CAPChannel: PSM, error: error)
        XYBleLog.debug(params:[
            "peripheralManager": peripheral.info,
            "PSM": String(PSM),
            "error": error?.localizedDescription ?? "nil",
        ])
    }

    /// L2CAP通道打开回调（iOS 11.0+）
    /// - Parameters:
    ///   - peripheral: 外设管理器实例
    ///   - channel: 打开的通道
    ///   - error: 错误信息
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

#endif
