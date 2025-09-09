//
//  XYBleDiscoverLogger.swift
//  XYCgms
//
//  Created by hsf on 2025/8/28.
//

import Foundation
import CoreBluetooth
import XYExtension
import XYUtil
import XYLog

// 每个peripheral每隔interval时间记录一次日志，避免日志过多
public final class XYBleDiscoverLogger {
    // MARK: var
    /// 外设Map
    public private(set) var peripheralMap = [String: Date]()
    /// 时间间隔
    public var interval: TimeInterval = 5
    
    /// 检测是否可记录日志
    public func log(tag: [String], peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber)  {
        let now = Date()
        let uuid = peripheral.identifier.uuidString
        if let lastTime = peripheralMap[uuid] {
            if lastTime.distance(to: now) > interval {
                appendNewInfo()
            }
        } else {
            appendNewInfo()
        }
        func appendNewInfo() {
            peripheralMap[uuid] = now
            XYLog.info(tag: tag, content: "advData=\(advertisementData.toJSONString() ?? "nil")", "rssi=\(RSSI)")
        }
    }
    
    /// 清空
    public func clear() {
        peripheralMap.removeAll()
    }
}


