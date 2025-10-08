//
//  XYConnectionPool.swift
//  XYCoreBluetooth
//
//  Created by AI Assistant on 2025/10/04.
//

import Foundation
import CoreBluetooth
import XYLog

// MARK: - ConnectionPriority
/// 连接优先级枚举
public extension XYConnectionPool {
    enum ConnectionPriority {
        case low
        case normal
        case high
    }
}

// MARK: - XYConnectionPool
/// 连接池管理器，用于管理多个蓝牙连接
public class XYConnectionPool {
    // MARK: - Singleton
    public static let shared = XYConnectionPool()
    private init() {}
    
    // MARK: - Properties
    /// 最大连接数
    public var maxConnections: Int = 5
    
    /// 当前连接的设备
    private var connections: [UUID: CBPeripheral] = [:]
    
    /// 连接优先级映射
    private var connectionPriorities: [UUID: ConnectionPriority] = [:]
    
    /// 连接池状态变化回调
    public var onPoolStatusChanged: ((Int, Int) -> Void)? // (current, max)
    
    /// 添加连接
    /// - Parameters:
    ///   - peripheral: 要添加的外设
    ///   - priority: 连接优先级
    /// - Returns: 是否添加成功
    @discardableResult
    public func addConnection(_ peripheral: CBPeripheral, priority: ConnectionPriority = .normal) -> Bool {
        let uuid = peripheral.identifier
        
        // 如果已经连接，直接返回
        if connections[uuid] != nil {
            connectionPriorities[uuid] = priority
            notifyStatusChanged()
            return true
        }
        
        // 检查是否达到最大连接数
        if connections.count >= maxConnections {
            // 如果有低优先级的连接，可以考虑断开它
            if let lowPriorityUUID = findLowPriorityConnection(than: priority) {
                removeConnection(for: lowPriorityUUID)
            } else {
                // 没有更低优先级的连接，无法添加新连接
                XYLog.info(tag: ["ConnectionPool", "addConnection"], process: .fail, content: "Max connections reached")
                return false
            }
        }
        
        connections[uuid] = peripheral
        connectionPriorities[uuid] = priority
        notifyStatusChanged()
        XYLog.info(tag: ["ConnectionPool", "addConnection"], process: .succ, content: "Added connection for \(uuid)")
        return true
    }
    
    /// 移除连接
    /// - Parameter uuid: 外设UUID
    public func removeConnection(for uuid: UUID) {
        connections.removeValue(forKey: uuid)
        connectionPriorities.removeValue(forKey: uuid)
        notifyStatusChanged()
        XYLog.info(tag: ["ConnectionPool", "removeConnection"], process: .succ, content: "Removed connection for \(uuid)")
    }
    
    /// 移除连接
    /// - Parameter peripheral: 外设
    public func removeConnection(_ peripheral: CBPeripheral) {
        removeConnection(for: peripheral.identifier)
    }
    
    /// 获取所有连接
    /// - Returns: 当前所有连接的外设
    public func getAllConnections() -> [CBPeripheral] {
        return Array(connections.values)
    }
    
    /// 检查是否已连接
    /// - Parameter uuid: 外设UUID
    /// - Returns: 是否已连接
    public func isConnected(_ uuid: UUID) -> Bool {
        return connections[uuid] != nil
    }
    
    /// 检查是否已连接
    /// - Parameter peripheral: 外设
    /// - Returns: 是否已连接
    public func isConnected(_ peripheral: CBPeripheral) -> Bool {
        return isConnected(peripheral.identifier)
    }
    
    /// 获取连接数
    /// - Returns: 当前连接数
    public func connectionCount() -> Int {
        return connections.count
    }
    
    /// 清空所有连接
    public func clearAllConnections() {
        connections.removeAll()
        connectionPriorities.removeAll()
        notifyStatusChanged()
        XYLog.info(tag: ["ConnectionPool", "clearAllConnections"], process: .succ, content: "Cleared all connections")
    }
    
    /// 查找比指定优先级更低的连接
    /// - Parameter priority: 指定优先级
    /// - Returns: 找到的低优先级连接UUID，如果没有则返回nil
    private func findLowPriorityConnection(than priority: ConnectionPriority) -> UUID? {
        for (uuid, connectionPriority) in connectionPriorities {
            if isLowerPriority(connectionPriority, than: priority) {
                return uuid
            }
        }
        return nil
    }
    
    /// 判断优先级是否更低
    /// - Parameters:
    ///   - current: 当前优先级
    ///   - target: 目标优先级
    /// - Returns: 当前优先级是否低于目标优先级
    private func isLowerPriority(_ current: ConnectionPriority, than target: ConnectionPriority) -> Bool {
        switch (current, target) {
        case (.low, .normal), (.low, .high), (.normal, .high):
            return true
        default:
            return false
        }
    }
    
    /// 通知连接池状态变化
    private func notifyStatusChanged() {
        onPoolStatusChanged?(connections.count, maxConnections)
    }
}
