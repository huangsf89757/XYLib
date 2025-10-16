//
//  XYCentralManagerDelegate.swift
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

// MARK: - XYCentralManagerDelegate
/// 蓝牙中心管理器代理协议，继承自CBCentralManagerDelegate，扩展了额外的代理方法
public protocol XYCentralManagerDelegate: CBCentralManagerDelegate {
    /// 检索外设结果回调
    /// - Parameters:
    ///   - central: 中心管理器实例
    ///   - identifiers: 外设标识符数组
    ///   - peripherals: 检索到的外设数组
    @available(iOS 7.0, *)
    func centralManager(_ central: CBCentralManager, retrievePeripheralsWithIdentifiers identifiers: [UUID], returns peripherals: [CBPeripheral])
    
    /// 检索已连接外设结果回调
    /// - Parameters:
    ///   - central: 中心管理器实例
    ///   - serviceUUIDs: 服务UUID数组
    ///   - peripherals: 检索到的外设数组
    @available(iOS 7.0, *)
    func centralManager(_ central: CBCentralManager, retrieveConnectedPeripheralsWithServices serviceUUIDs: [CBUUID], returns peripherals: [CBPeripheral])
    
    /// 开始扫描外设回调
    /// - Parameters:
    ///   - central: 中心管理器实例
    ///   - serviceUUIDs: 要扫描的服务UUID数组
    ///   - options: 扫描选项
    func centralManager(_ central: CBCentralManager, scanForPeripheralsWithServices serviceUUIDs: [CBUUID]?, options: [String: Any]?)
    
    /// 停止扫描回调
    /// - Parameters:
    ///   - central: 中心管理器实例
    ///   - _: 空参数
    func centralManager(_ central: CBCentralManager, stopScan: Void)
    
    /// 连接外设回调
    /// - Parameters:
    ///   - central: 中心管理器实例
    ///   - peripheral: 要连接的外设
    ///   - options: 连接选项
    func centralManager(_ central: CBCentralManager, connect peripheral: CBPeripheral, options: [String: Any]?)
    
    /// 取消连接外设回调
    /// - Parameters:
    ///   - central: 中心管理器实例
    ///   - peripheral: 要断开连接的外设
    func centralManager(_ central: CBCentralManager, cancelPeripheralConnection peripheral: CBPeripheral)
    
    /// 注册连接事件回调（iOS 13.0+）
    /// - Parameters:
    ///   - central: 中心管理器实例
    ///   - options: 连接事件匹配选项
    @available(iOS 13.0, *)
    func centralManager(_ central: CBCentralManager, registerForConnectionEventsWithOptions options: [CBConnectionEventMatchingOption: Any]?)
}

// MARK: - Default Implementation
public extension XYCentralManagerDelegate {
    @available(iOS 7.0, *)
    func centralManager(_ central: CBCentralManager, retrievePeripheralsWithIdentifiers identifiers: [UUID], returns peripherals: [CBPeripheral]) {}
    
    @available(iOS 7.0, *)
    func centralManager(_ central: CBCentralManager, retrieveConnectedPeripheralsWithServices serviceUUIDs: [CBUUID], returns peripherals: [CBPeripheral]) {}
    
    func centralManager(_ central: CBCentralManager, scanForPeripheralsWithServices serviceUUIDs: [CBUUID]?, options: [String: Any]?) {}
    
    func centralManager(_ central: CBCentralManager, stopScan: Void) {}
    
    func centralManager(_ central: CBCentralManager, connect peripheral: CBPeripheral, options: [String: Any]?) {}
    
    func centralManager(_ central: CBCentralManager, cancelPeripheralConnection peripheral: CBPeripheral) {}
    
    @available(iOS 13.0, *)
    func centralManager(_ central: CBCentralManager, registerForConnectionEventsWithOptions options: [CBConnectionEventMatchingOption: Any]?) {}
}
