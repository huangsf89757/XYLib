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
/// 蓝牙中心管理器代理协议，继承自CBCentralManagerDelegate
/// 
/// 该协议扩展了系统的CBCentralManagerDelegate，增加了操作发起时机的通知方法，
/// 使得代理可以监控中心管理器的所有操作行为，方便调试和状态跟踪。
public protocol XYCentralManagerDelegate: CBCentralManagerDelegate {
    // MARK: - Retrieve
    /// 检索外设通知
    /// - Parameters:
    ///   - central: 中心管理器实例
    ///   - identifiers: 外设标识符数组
    ///   - peripherals: 检索到的外设数组
    @available(iOS 7.0, *)
    func centralManager(_ central: CBCentralManager, retrievePeripheralsWithIdentifiers identifiers: [UUID], returns peripherals: [CBPeripheral])
    
    /// 检索已连接外设通知
    /// - Parameters:
    ///   - central: 中心管理器实例
    ///   - serviceUUIDs: 服务UUID数组
    ///   - peripherals: 检索到的已连接外设数组
    @available(iOS 7.0, *)
    func centralManager(_ central: CBCentralManager, retrieveConnectedPeripheralsWithServices serviceUUIDs: [CBUUID], returns peripherals: [CBPeripheral])
    
    // MARK: - Scan
    /// 扫描外设通知
    /// - Parameters:
    ///   - central: 中心管理器实例
    ///   - serviceUUIDs: 要扫描的服务UUID数组，为nil时扫描所有外设
    ///   - options: 扫描选项，如CBCentralManagerScanOptionAllowDuplicatesKey等
    func centralManager(_ central: CBCentralManager, scanForPeripheralsWithServices serviceUUIDs: [CBUUID]?, options: [String: Any]?)
    
    /// 停止扫描通知
    /// - Parameters:
    ///   - central: 中心管理器实例
    ///   - _: 空参数
    func centralManager(_ central: CBCentralManager, stopScan: Void)
    
    // MARK: - Connection
    /// 连接外设通知
    /// - Parameters:
    ///   - central: 中心管理器实例
    ///   - peripheral: 要连接的外设
    ///   - options: 连接选项
    func centralManager(_ central: CBCentralManager, connect peripheral: CBPeripheral, options: [String: Any]?)
    
    /// 取消外设连接通知
    /// - Parameters:
    ///   - central: 中心管理器实例
    ///   - peripheral: 要取消连接的外设
    func centralManager(_ central: CBCentralManager, cancelPeripheralConnection peripheral: CBPeripheral)
    
    // MARK: - Events
    /// 注册连接事件通知（iOS 13.0+）
    /// - Parameters:
    ///   - central: 中心管理器实例
    ///   - peripheral: 目标外设
    ///   - options: 注册选项
    @available(iOS 13.0, *)
    func centralManager(_ central: CBCentralManager, registerForConnectionEventsWith peripheral: CBPeripheral, options: [String: Any]?)
}

// MARK: - Default Implementation
/// XYCentralManagerDelegate的默认实现扩展
/// 
/// 为所有代理方法提供空实现，使得遵循该协议的类不需要实现所有方法。
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
