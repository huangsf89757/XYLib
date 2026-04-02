//
//  XYPeripheralManagerDelegate.swift
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

// MARK: - XYPeripheralManagerDelegate
/// 外设管理器代理协议，继承自 CBPeripheralManagerDelegate，并补充发起操作通知
/// 
/// 该协议扩展了系统的CBPeripheralManagerDelegate，增加了操作发起时机的通知方法，
/// 使得代理可以监控外设管理器的所有操作行为，方便调试和状态跟踪。
public protocol XYPeripheralManagerDelegate: CBPeripheralManagerDelegate {
    // MARK: - Advertising
    /// 开始广播通知
    /// - Parameters:
    ///   - peripheral: 外设管理器实例
    ///   - advertisementData: 广播数据字典
    func peripheralManager(_ peripheral: CBPeripheralManager, startAdvertising advertisementData: [String: Any]?)
    
    /// 停止广播通知
    /// - Parameters:
    ///   - peripheral: 外设管理器实例
    ///   - _: 空参数
    func peripheralManager(_ peripheral: CBPeripheralManager, stopAdvertising: Void)

    // MARK: - Services
    /// 添加服务通知
    /// - Parameters:
    ///   - peripheral: 外设管理器实例
    ///   - service: 要添加的可变服务
    func peripheralManager(_ peripheral: CBPeripheralManager, add service: CBMutableService)
    
    /// 移除服务通知
    /// - Parameters:
    ///   - peripheral: 外设管理器实例
    ///   - service: 要移除的可变服务
    func peripheralManager(_ peripheral: CBPeripheralManager, remove service: CBMutableService)
    
    /// 移除所有服务通知
    /// - Parameters:
    ///   - peripheral: 外设管理器实例
    ///   - _: 空参数
    func peripheralManager(_ peripheral: CBPeripheralManager, removeAllServices: Void)

    // MARK: - Connection Latency
    /// 设置期望连接时延通知
    /// - Parameters:
    ///   - peripheral: 外设管理器实例
    ///   - latency: 期望的连接时延
    ///   - central: 目标中心设备
    func peripheralManager(_ peripheral: CBPeripheralManager, setDesiredConnectionLatency latency: CBPeripheralManagerConnectionLatency, for central: CBCentral)

    // MARK: - I/O Operations
    /// 更新特征值通知
    /// - Parameters:
    ///   - peripheral: 外设管理器实例
    ///   - value: 要更新的数据
    ///   - characteristic: 目标特征
    ///   - centrals: 订阅的中心设备数组，为nil时发送给所有订阅者
    ///   - ok: 操作是否成功
    func peripheralManager(_ peripheral: CBPeripheralManager, updateValue value: Data, for characteristic: CBMutableCharacteristic, onSubscribedCentrals centrals: [CBCentral]?, returns ok: Bool)
    
    /// 响应读写请求通知
    /// - Parameters:
    ///   - peripheral: 外设管理器实例
    ///   - request: 要响应的ATT请求
    ///   - result: 响应结果代码
    func peripheralManager(_ peripheral: CBPeripheralManager, respondTo request: CBATTRequest, withResult result: CBATTError.Code)

    // MARK: - L2CAP Channels
    /// 发布L2CAP通道通知（iOS 11.0+）
    /// - Parameters:
    ///   - peripheral: 外设管理器实例
    ///   - encryptionRequired: 是否需要加密
    @available(iOS 11.0, *)
    func peripheralManager(_ peripheral: CBPeripheralManager, publishL2CAPChannelWithEncryption encryptionRequired: Bool)
    
    /// 取消发布L2CAP通道通知（iOS 11.0+）
    /// - Parameters:
    ///   - peripheral: 外设管理器实例
    ///   - PSM: 协议/服务复用器值
    @available(iOS 11.0, *)
    func peripheralManager(_ peripheral: CBPeripheralManager, unpublishL2CAPChannel PSM: CBL2CAPPSM)
}

// MARK: - Default Implementation
/// XYPeripheralManagerDelegate的默认实现扩展
/// 
/// 为所有代理方法提供空实现，使得遵循该协议的类不需要实现所有方法。
public extension XYPeripheralManagerDelegate {
    func peripheralManager(_ peripheral: CBPeripheralManager, startAdvertising advertisementData: [String: Any]?) {}
    
    func peripheralManager(_ peripheral: CBPeripheralManager, stopAdvertising: Void) {}
    
    func peripheralManager(_ peripheral: CBPeripheralManager, add service: CBMutableService) {}
    
    func peripheralManager(_ peripheral: CBPeripheralManager, remove service: CBMutableService) {}
    
    func peripheralManager(_ peripheral: CBPeripheralManager, removeAllServices: Void) {}
    
    func peripheralManager(_ peripheral: CBPeripheralManager, setDesiredConnectionLatency latency: CBPeripheralManagerConnectionLatency, for central: CBCentral) {}
    
    func peripheralManager(_ peripheral: CBPeripheralManager, updateValue value: Data, for characteristic: CBMutableCharacteristic, onSubscribedCentrals centrals: [CBCentral]?, returns ok: Bool) {}
    
    func peripheralManager(_ peripheral: CBPeripheralManager, respondTo request: CBATTRequest, withResult result: CBATTError.Code) {}
    
    @available(iOS 11.0, *)
    func peripheralManager(_ peripheral: CBPeripheralManager, publishL2CAPChannelWithEncryption encryptionRequired: Bool) {}
    
    @available(iOS 11.0, *)
    func peripheralManager(_ peripheral: CBPeripheralManager, unpublishL2CAPChannel PSM: CBL2CAPPSM) {}
}

#endif
