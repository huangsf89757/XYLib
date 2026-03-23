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
    
    // MARK: func
    /// 检查是否被节流
    /// - Parameter tag: 标签
    /// - Returns: 是否被节流
    public func check(tag: XYLogTag?, action: @escaping () -> Void) {
        guard let tag else {
            action()
            return
        }
        switch tag {
        case .com(let contents):
            guard let com else {
                action()
                return
            }
            com.work(action: action)
        case .tag(contents: let contents, throttle: let interval):
            syncQueue.async(flags: .barrier) { [weak self] in
               guard let self = self else { return }
                let key = contents.joined(separator: ".")
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
