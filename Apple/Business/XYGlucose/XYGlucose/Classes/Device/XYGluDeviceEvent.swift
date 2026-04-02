//
//  XYGluDeviceEvent.swift
//  XYCgms
//
//  Created by hsf on 2025/12/12.
//

import Foundation

// MARK: - XYGluDevice.Event
/// 设备事件
extension XYGluDevice {
    public struct Event {
        // MARK: Result
        public enum Result: Int {
            case start  = -1    // 开始
            case succ   = 0     // 成功
            case fail   = 1     // 失败
        }
        
        // MARK: Type
        public enum `Type`: Int {
            case pair       = 0 // 配对
            case activate   = 1 // 激活
            case calibrate  = 2 // 校准
            case unpair     = 3 // 解配
        }
        
        // MARK: var
        /// ID
        public var id: String = UUID().uuidString
        /// 类型
        public let type: `Type`
        /// 结果
        public let result: Result
        /// 时间
        public let date: Date
        /// 备注
        public let remark: String
    }
}

