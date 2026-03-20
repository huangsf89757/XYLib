//
//  XYLogTag.swift
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

// MARK: - XYLogTag
public class XYLogTag {
    /// 内容
    public var contents: [String] = []
    /// 防抖
    public var debounce: XYDebounce?
    /// 节流
    public var throttle: XYThrottle?
    
    /// 初始化
    /// - Parameters:
    ///   - contents: 标签内容
    ///   - debounceDelay: 防抖延迟时间 (秒)，<=0 表示不开启防抖
    ///   - throttleInterval: 节流间隔时间 (秒)，<=0 表示不开启节流
    public init(contents: [String], debounce: TimeInterval = 0, throttle: TimeInterval = 0) {
        self.contents = contents
        if debounce > 0 {
            self.debounce = XYDebounce(delay: debounce, queue: .global())
        }
        if throttle > 0 {
            self.throttle = XYThrottle(interval: throttle, queue: .global())
        }
    }    
}

// MARK: - Tag
extension XYLogTag {
    public static func getId(tag: [String]) -> String {
        return tag.joined(separator: ".")
    }
    public func getId(tag: [String]) -> String {
        return Self.getId(tag: contents)
    }
}
