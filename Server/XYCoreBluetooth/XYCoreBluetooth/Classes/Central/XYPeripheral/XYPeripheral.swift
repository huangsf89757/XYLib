//
//  XYPeripheral.swift
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

// MARK: - XYPeripheral
/// 蓝牙外设包装类，封装了CBPeripheral的功能，提供服务发现、特征读写等操作
open class XYPeripheral: NSObject {
    // MARK: Property
    /// CBPeripheral实例，系统蓝牙外设对象
    public private(set) var peripheral: CBPeripheral!
    /// 代理
    public weak var delegate: (any XYPeripheralDelegate)?

    /// 外设名称
    open var name: String? { peripheral.name }
    /// 标识符
    open var identifier: UUID { peripheral.identifier }
    /// 当前服务列表
    open var services: [CBService]? { peripheral.services }

    // MARK: Life Cycle
    /// 初始化蓝牙外设管理器
    /// - Parameters:
    ///   - peripheral: 系统外设对象
    ///   - delegate: 代理对象，用于处理蓝牙事件回调
    public init(peripheral: CBPeripheral, delegate: (any XYPeripheralDelegate)? = nil) {
        super.init()
        self.peripheral = peripheral
        self.delegate = delegate
        self.peripheral.delegate = self
        XYBleLog.debug(params:[
            "peripheral": peripheral.info,
            "delegate": delegate?.description ?? "nil",
        ])
    }

    // MARK: RSSI
    /// 读取RSSI信号强度
    open func readRSSI() {
        peripheral.readRSSI()
        XYBleLog.debug()
        self.delegate?.peripheral(peripheral, readRSSI: ())
    }

    // MARK: Service
    /// 发现外设的服务
    /// - Parameter serviceUUIDs: 要发现的服务UUID数组，为nil时发现所有服务
    open func discoverServices(_ serviceUUIDs: [CBUUID]?) {
        peripheral.discoverServices(serviceUUIDs)
        XYBleLog.debug(params:[
            "serviceUUIDs": serviceUUIDs?.map{ $0.uuidString }.toJSONString() ?? "nil",
        ])
        self.delegate?.peripheral(peripheral, discoverServices: serviceUUIDs)
    }

    /// 发现服务的包含服务
    /// - Parameters:
    ///   - includedServiceUUIDs: 要发现的包含服务UUID数组
    ///   - service: 父服务对象
    open func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?, for service: CBService) {
        peripheral.discoverIncludedServices(includedServiceUUIDs, for: service)
        XYBleLog.debug(params:[
            "includedServiceUUIDs": includedServiceUUIDs?.map{ $0.uuidString }.toJSONString() ?? "nil",
            "service": service.info,
        ])
        self.delegate?.peripheral(peripheral, discoverIncludedServices: includedServiceUUIDs, for: service)
    }

    // MARK: Characteristic
    /// 发现服务的特征
    /// - Parameters:
    ///   - characteristicUUIDs: 要发现的特征UUID数组，为nil时发现所有特征
    ///   - service: 目标服务对象
    open func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBService) {
        peripheral.discoverCharacteristics(characteristicUUIDs, for: service)
        XYBleLog.debug(params:[
            "characteristicUUIDs": characteristicUUIDs?.map{ $0.uuidString }.toJSONString() ?? "nil",
            "service": service.info,
        ])
        self.delegate?.peripheral(peripheral, discoverCharacteristics: characteristicUUIDs, for: service)
    }

    /// 读取特征值数据
    /// - Parameter characteristic: 目标特征对象
    open func readValue(for characteristic: CBCharacteristic) {
        peripheral.readValue(for: characteristic)
        XYBleLog.debug(params:[
            "characteristic": characteristic.info,
        ])
        self.delegate?.peripheral(peripheral, readValueFor: characteristic)
    }

    /// 写入数据到特征值
    /// - Parameters:
    ///   - data: 要写入的数据
    ///   - characteristic: 目标特征对象
    ///   - type: 写入类型（带响应或无响应）
    open func writeValue(_ data: Data, for characteristic: CBCharacteristic, type: CBCharacteristicWriteType) {
        peripheral.writeValue(data, for: characteristic, type: type)
        XYBleLog.debug(params:[
            "data.count": String(data.count),
            "characteristic": characteristic.info,
            "type": String(describing: type),
        ])
        self.delegate?.peripheral(peripheral, writeValue: data, for: characteristic, type: type)
    }

    /// 设置特征的通知状态
    /// - Parameters:
    ///   - enabled: 是否启用通知
    ///   - characteristic: 目标特征对象
    open func setNotifyValue(_ enabled: Bool, for characteristic: CBCharacteristic) {
        peripheral.setNotifyValue(enabled, for: characteristic)
        XYBleLog.debug(params:[
            "enabled": String(enabled),
            "characteristic": characteristic.info,
        ])
        self.delegate?.peripheral(peripheral, setNotifyValue: enabled, for: characteristic)
    }

    // MARK: Descriptor
    /// 发现特征的描述符
    /// - Parameter characteristic: 目标特征对象
    open func discoverDescriptors(for characteristic: CBCharacteristic) {
        peripheral.discoverDescriptors(for: characteristic)
        XYBleLog.debug(params:[
            "characteristic": characteristic.info,
        ])
        self.delegate?.peripheral(peripheral, discoverDescriptorsFor: characteristic)
    }

    /// 读取描述符的值
    /// - Parameter descriptor: 目标描述符对象
    open func readValue(for descriptor: CBDescriptor) {
        peripheral.readValue(for: descriptor)
        XYBleLog.debug(params:[
            "descriptor": descriptor.info,
        ])
        self.delegate?.peripheral(peripheral, readValueFor: descriptor)
    }

    /// 写入数据到描述符
    /// - Parameters:
    ///   - data: 要写入的数据
    ///   - descriptor: 目标描述符对象
    open func writeValue(_ data: Data, for descriptor: CBDescriptor) {
        peripheral.writeValue(data, for: descriptor)
        XYBleLog.debug(params:[
            "data.count": String(data.count),
            "descriptor": descriptor.info,
        ])
        self.delegate?.peripheral(peripheral, writeValue: data, for: descriptor)
    }

    // MARK: MTU
    /// 获取特征最大可写数据长度（iOS 9.0+）
    /// - Parameter type: 写入类型
    /// - Returns: 最大可写入数据的字节数
    @available(iOS 9.0, *)
    open func maximumWriteValueLength(for type: CBCharacteristicWriteType) -> Int {
        let len = peripheral.maximumWriteValueLength(for: type)
        XYBleLog.debug(params:[
            "type": String(describing: type),
        ], returns: String(len))
        self.delegate?.peripheral(peripheral, maximumWriteValueLengthFor: type, returns: len)
        return len
    }
}

// MARK: - CBPeripheralDelegate
extension XYPeripheral: CBPeripheralDelegate {
    /// 外设名称更新回调
    /// - Parameter peripheral: 外设实例
    public func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        self.delegate?.peripheralDidUpdateName?(peripheral)
        XYBleLog.debug(params:[
            "peripheral": peripheral.info,
        ])
    }

    /// 外设服务修改回调
    /// - Parameters:
    ///   - peripheral: 外设实例
    ///   - invalidatedServices: 失效的服务数组
    public func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        self.delegate?.peripheral?(peripheral, didModifyServices: invalidatedServices)
        XYBleLog.debug(params:[
            "peripheral": peripheral.info,
            "invalidatedServices.count": String(invalidatedServices.count),
        ])
    }

    /// RSSI更新完成回调
    /// - Parameters:
    ///   - peripheral: 外设实例
    ///   - error: 错误信息
    public func peripheralDidUpdateRSSI(_ peripheral: CBPeripheral, error: (any Error)?) {
        self.delegate?.peripheralDidUpdateRSSI?(peripheral, error: error)
        XYBleLog.debug(params:[
            "peripheral": peripheral.info,
            "error": error?.localizedDescription ?? "nil",
        ])
    }

    /// 读取RSSI完成回调
    /// - Parameters:
    ///   - peripheral: 外设实例
    ///   - RSSI: 信号强度值
    ///   - error: 错误信息
    public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: (any Error)?) {
        self.delegate?.peripheral?(peripheral, didReadRSSI: RSSI, error: error)
        XYBleLog.debug(params:[
            "peripheral": peripheral.info,
            "RSSI": RSSI.stringValue,
            "error": error?.localizedDescription ?? "nil",
        ])
    }

    /// 发现服务完成回调
    /// - Parameters:
    ///   - peripheral: 外设实例
    ///   - error: 错误信息
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        self.delegate?.peripheral?(peripheral, didDiscoverServices: error)
        XYBleLog.debug(params:[
            "peripheral": peripheral.info,
            "services.count": String(peripheral.services?.count ?? 0),
            "error": error?.localizedDescription ?? "nil",
        ])
    }

    /// 发现包含服务完成回调
    /// - Parameters:
    ///   - peripheral: 外设实例
    ///   - service: 父服务对象
    ///   - error: 错误信息
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: (any Error)?) {
        self.delegate?.peripheral?(peripheral, didDiscoverIncludedServicesFor: service, error: error)
        XYBleLog.debug(params:[
            "peripheral": peripheral.info,
            "service": service.info,
            "error": error?.localizedDescription ?? "nil",
        ])
    }

    /// 发现特征完成回调
    /// - Parameters:
    ///   - peripheral: 外设实例
    ///   - service: 服务对象
    ///   - error: 错误信息
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
        self.delegate?.peripheral?(peripheral, didDiscoverCharacteristicsFor: service, error: error)
        XYBleLog.debug(params:[
            "peripheral": peripheral.info,
            "service": service.info,
            "characteristics.count": String(service.characteristics?.count ?? 0),
            "error": error?.localizedDescription ?? "nil",
        ])
    }

    /// 特征值更新回调
    /// - Parameters:
    ///   - peripheral: 外设实例
    ///   - characteristic: 特征对象
    ///   - error: 错误信息
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        self.delegate?.peripheral?(peripheral, didUpdateValueFor: characteristic, error: error)
        XYBleLog.debug(params:[
            "peripheral": peripheral.info,
            "characteristic": characteristic.info,
            "value.count": String(characteristic.value?.count ?? 0),
            "error": error?.localizedDescription ?? "nil",
        ])
    }

    /// 特征值写入完成回调
    /// - Parameters:
    ///   - peripheral: 外设实例
    ///   - characteristic: 特征对象
    ///   - error: 错误信息
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        self.delegate?.peripheral?(peripheral, didWriteValueFor: characteristic, error: error)
        XYBleLog.debug(params:[
            "peripheral": peripheral.info,
            "characteristic": characteristic.info,
            "error": error?.localizedDescription ?? "nil",
        ])
    }

    /// 特征通知状态更新回调
    /// - Parameters:
    ///   - peripheral: 外设实例
    ///   - characteristic: 特征对象
    ///   - error: 错误信息
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: (any Error)?) {
        self.delegate?.peripheral?(peripheral, didUpdateNotificationStateFor: characteristic, error: error)
        XYBleLog.debug(params:[
            "peripheral": peripheral.info,
            "characteristic": characteristic.info,
            "isNotifying": String(characteristic.isNotifying),
            "error": error?.localizedDescription ?? "nil",
        ])
    }

    /// 发现描述符完成回调
    /// - Parameters:
    ///   - peripheral: 外设实例
    ///   - characteristic: 特征对象
    ///   - error: 错误信息
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: (any Error)?) {
        self.delegate?.peripheral?(peripheral, didDiscoverDescriptorsFor: characteristic, error: error)
        XYBleLog.debug(params:[
            "peripheral": peripheral.info,
            "characteristic": characteristic.info,
            "descriptors.count": String(characteristic.descriptors?.count ?? 0),
            "error": error?.localizedDescription ?? "nil",
        ])
    }

    /// 描述符值更新回调
    /// - Parameters:
    ///   - peripheral: 外设实例
    ///   - descriptor: 描述符对象
    ///   - error: 错误信息
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: (any Error)?) {
        self.delegate?.peripheral?(peripheral, didUpdateValueFor: descriptor, error: error)
        XYBleLog.debug(params:[
            "peripheral": peripheral.info,
            "descriptor": descriptor.info,
            "error": error?.localizedDescription ?? "nil",
        ])
    }

    /// 描述符值写入完成回调
    /// - Parameters:
    ///   - peripheral: 外设实例
    ///   - descriptor: 描述符对象
    ///   - error: 错误信息
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: (any Error)?) {
        self.delegate?.peripheral?(peripheral, didWriteValueFor: descriptor, error: error)
        XYBleLog.debug(params:[
            "peripheral": peripheral.info,
            "descriptor": descriptor.info,
            "error": error?.localizedDescription ?? "nil",
        ])
    }

    /// 准备好发送无响应写入回调（iOS 11.0+）
    /// - Parameter peripheral: 外设实例
    @available(iOS 11.0, *)
    public func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        self.delegate?.peripheralIsReady?(toSendWriteWithoutResponse: peripheral)
        XYBleLog.debug(params:[
            "peripheral": peripheral.info,
        ])
    }

    /// L2CAP通道打开完成回调（iOS 11.0+）
    /// - Parameters:
    ///   - peripheral: 外设实例
    ///   - channel: 打开的L2CAP通道
    ///   - error: 错误信息
    @available(iOS 11.0, *)
    public func peripheral(_ peripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: (any Error)?) {
        self.delegate?.peripheral?(peripheral, didOpen: channel, error: error)
        XYBleLog.debug(params:[
            "peripheral": peripheral.info,
            "channel": channel?.description ?? "nil",
            "error": error?.localizedDescription ?? "nil",
        ])
    }
}


