//
//  XYLogThrottle.swift
//  XYLog
//
//  Created by hsf on 2025/9/2.
//

// MARK: - Import
// System
import Foundation
// Basic
// Service
// Tool
import XYUtil
// Business
// Third

// MARK: - XYLogThrottle
public class XYLogThrottle {
    // MARK: var
    /// 通用节流器
    private var com: XYThrottle?
    /// 标签节流器
    private var tagMap: [String: XYThrottle] = [:]
    /// 同步队列
    private let syncQueue = DispatchQueue(label: "com.xy.log.throttle.map", attributes: .concurrent)
    
    public enum Method {
        case com(throttle: TimeInterval)
        case tag(throttle: TimeInterval, key: String)
    }
    
    // MARK: func
    /// 检查是否被节流
    /// - Parameter type: 类型
    /// - Returns: 是否被节流
    public func check(method: Method?, action: @escaping () -> Void) {
        guard let method else {
            action()
            return
        }
        switch method {
        case .com(throttle: let interval):
            guard let com else {
                action()
                return
            }
            com.interval = interval
            com.work(action: action)
        case .tag(throttle: let interval, key: let key):
            syncQueue.async(flags: .barrier) { [weak self] in
               guard let self = self else { return }
               if let throttle = self.tagMap[key] {
                   throttle.work(interval: interval, action: action)
               } else {
                   let throttle = XYThrottle(interval: interval)
                   self.tagMap[key] = throttle
                   throttle.work(action: action)
               }
           }
        }
    }
}


