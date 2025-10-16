//
//  XYPeripheralDelegate.swift
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

// MARK: - XYPeripheralDelegate
/// 蓝牙外设代理协议，继承自 CBPeripheralDelegate，扩展操作发起时机的通知
/// 
/// 该协议扩展了系统的CBPeripheralDelegate，增加了操作发起时机的通知方法，
/// 使得代理可以监控外设的所有操作行为，方便调试和状态跟踪。
public protocol XYPeripheralDelegate: CBPeripheralDelegate {
    // MARK: - RSSI
    /// 读取RSSI通知
    /// - Parameters:
    ///   - peripheral: 外设实例
    ///   - _: 空参数
    func peripheral(_ peripheral: CBPeripheral, readRSSI: Void)

    // MARK: - Services
    /// 发现服务通知
    /// - Parameters:
    ///   - peripheral: 外设实例
    ///   - serviceUUIDs: 要发现的服务UUID数组，为nil时发现所有服务
    func peripheral(_ peripheral: CBPeripheral, discoverServices serviceUUIDs: [CBUUID]?)

    /// 发现包含服务通知
    /// - Parameters:
    ///   - peripheral: 外设实例
    ///   - includedServiceUUIDs: 要发现的包含服务UUID数组，为nil时发现所有包含服务
    ///   - service: 父服务
    func peripheral(_ peripheral: CBPeripheral, discoverIncludedServices includedServiceUUIDs: [CBUUID]?, for service: CBService)

    // MARK: - Characteristics
    /// 发现特征通知
    /// - Parameters:
    ///   - peripheral: 外设实例
    ///   - characteristicUUIDs: 要发现的特征UUID数组，为nil时发现所有特征
    ///   - service: 目标服务
    func peripheral(_ peripheral: CBPeripheral, discoverCharacteristics characteristicUUIDs: [CBUUID]?, for service: CBService)

    /// 读取特征值通知
    /// - Parameters:
    ///   - peripheral: 外设实例
    ///   - characteristic: 目标特征
    func peripheral(_ peripheral: CBPeripheral, readValueFor characteristic: CBCharacteristic)

    /// 写入特征值通知
    /// - Parameters:
    ///   - peripheral: 外设实例
    ///   - data: 要写入的数据
    ///   - characteristic: 目标特征
    ///   - type: 写入类型
    func peripheral(_ peripheral: CBPeripheral, writeValue data: Data, for characteristic: CBCharacteristic, type: CBCharacteristicWriteType)

    /// 设置通知状态通知
    /// - Parameters:
    ///   - peripheral: 外设实例
    ///   - enabled: 是否启用通知
    ///   - characteristic: 目标特征
    func peripheral(_ peripheral: CBPeripheral, setNotifyValue enabled: Bool, for characteristic: CBCharacteristic)

    // MARK: - Descriptors
    /// 发现描述符通知
    /// - Parameters:
    ///   - peripheral: 外设实例
    ///   - characteristic: 目标特征
    func peripheral(_ peripheral: CBPeripheral, discoverDescriptorsFor characteristic: CBCharacteristic)

    /// 读取描述符值通知
    /// - Parameters:
    ///   - peripheral: 外设实例
    ///   - descriptor: 目标描述符
    func peripheral(_ peripheral: CBPeripheral, readValueFor descriptor: CBDescriptor)

    /// 写入描述符值通知
    /// - Parameters:
    ///   - peripheral: 外设实例
    ///   - data: 要写入的数据
    ///   - descriptor: 目标描述符
    func peripheral(_ peripheral: CBPeripheral, writeValue data: Data, for descriptor: CBDescriptor)

    // MARK: - Capabilities
    /// 获取最大可写值长度通知（iOS 9.0+）
    /// - Parameters:
    ///   - peripheral: 外设实例
    ///   - type: 写入类型
    ///   - length: 最大可写长度
    @available(iOS 9.0, *)
    func peripheral(_ peripheral: CBPeripheral, maximumWriteValueLengthFor type: CBCharacteristicWriteType, returns length: Int)
}

// MARK: - Default Implementation
/// XYPeripheralDelegate的默认实现扩展
/// 
/// 为所有代理方法提供空实现，使得遵循该协议的类不需要实现所有方法。
public extension XYPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, readRSSI: Void) {}

    func peripheral(_ peripheral: CBPeripheral, discoverServices serviceUUIDs: [CBUUID]?) {}

    func peripheral(_ peripheral: CBPeripheral, discoverIncludedServices includedServiceUUIDs: [CBUUID]?, for service: CBService) {}

    func peripheral(_ peripheral: CBPeripheral, discoverCharacteristics characteristicUUIDs: [CBUUID]?, for service: CBService) {}

    func peripheral(_ peripheral: CBPeripheral, readValueFor characteristic: CBCharacteristic) {}

    func peripheral(_ peripheral: CBPeripheral, writeValue data: Data, for characteristic: CBCharacteristic, type: CBCharacteristicWriteType) {}

    func peripheral(_ peripheral: CBPeripheral, setNotifyValue enabled: Bool, for characteristic: CBCharacteristic) {}

    func peripheral(_ peripheral: CBPeripheral, discoverDescriptorsFor characteristic: CBCharacteristic) {}

    func peripheral(_ peripheral: CBPeripheral, readValueFor descriptor: CBDescriptor) {}

    func peripheral(_ peripheral: CBPeripheral, writeValue data: Data, for descriptor: CBDescriptor) {}

    @available(iOS 9.0, *)
    func peripheral(_ peripheral: CBPeripheral, maximumWriteValueLengthFor type: CBCharacteristicWriteType, returns length: Int) {}
}


