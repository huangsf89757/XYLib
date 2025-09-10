//
//  XYAlertMethod.swift
//  XYCgms
//
//  Created by hsf on 2025/8/27.
//

import Foundation

// MARK: - 提醒方式
public struct XYAlertMethod: OptionSet {
    public let rawValue: Int
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    /// 声音
    public static let sound: Self = .init(rawValue: 1 << 0)
    
    /// 振动
    public static let vibration: Self = .init(rawValue: 1 << 1)
}

