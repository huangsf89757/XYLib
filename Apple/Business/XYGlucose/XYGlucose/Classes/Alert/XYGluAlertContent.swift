//
//  XYGluAlertContent.swift
//  XYCgms
//
//  Created by hsf on 2025/8/27.
//

import Foundation

// MARK: - XYGluAlert.Content
/// 提醒内容
extension XYGluAlert {
    public struct Content {
        /// 开关，默认开启
        public var enable = true
        /// 阈值
        public var threshold: XYGluData.Value?
        /// 提醒方式，默认声音和振动
        public var method: XYGluAlert.Method = [.sound, .vibration]
        /// 提醒间隔，默认15分钟
        public var interval: TimeInterval = 15 * 60
        /// 提醒时长，默认2秒
        public var duration: TimeInterval = 2
        
    }
}
