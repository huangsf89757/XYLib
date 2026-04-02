//
//  XYUserAuthorization.swift
//  XYUser
//
//  Created by hsf on 2026/3/18.
//

// MARK: - Import
// System
import Foundation
// Basic
// Service
import XYStorage
// Tool
// Business
// Third

// MARK: - XYUserAuthorization
/// 用户信息
public struct XYUserAuthorization: XYModelDatable {
    public var id: String
    public var createTime: Date
    public var updateTime: Date?
    
    /// UID
    public let uid: String
    /// 授权类型
    public let type: XYUserAuthType
    /// 认证信息
    public let info: String
}

// MARK: - XYUserAuthType
/// 授权类型
public enum XYUserAuthType: Int {
    case wechat = 0     // 微信
    case qq             // QQ
    case aliPay         // 支付宝
    case apple          // Apple
}
