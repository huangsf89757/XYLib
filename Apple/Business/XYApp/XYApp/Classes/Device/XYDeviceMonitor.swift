//
//  XYDeviceMonitor.swift
//  XYApp
//
//  Created by hsf on 2025/12/11.
//

// MARK: - Import
// System
import Foundation
// Basic
// Service
// Tool
// Business
// Third


// MARK: - XYDeviceMonitor
public final class XYDeviceMonitor {
    // MARK: shared
    public static let shared = XYDeviceMonitor()
    private init() {}
    
    // MARK: Monitor
    public enum Monitor {
        case powerState                 // 电池状态
        case battery                    // 电池电量
        case lowPowerMode               // 低电量模式
        case backgroundRefreshStatus    // 后台App刷新
    }
    
    // MARK: var
    public private(set) var isMonitoringBattery = false
    
    
}

//// MARK: - Battery
//extension XYDeviceMonitor {
//    public func startBatteryMonitoring(onChange: @escaping (Int?, XYDevice.BatteryState?) -> Void) {
//        isMonitoringBattery = true
//        UIDevice.current.isBatteryMonitoringEnabled = true
//        NotificationCenter.default.addObserver(
//            forName: UIDevice.batteryLevelDidChangeNotification,
//            object: nil,
//            queue: .main
//        ) { _ in
//            onChange(XYDevice.current.batteryLevel, XYDevice.current.batteryState)
//        }
//    }
//    
//    public func stopBatteryMonitoring() {
//        NotificationCenter.default.removeObserver(self, name: UIDevice.batteryLevelDidChangeNotification, object: nil)
//    }
//}
