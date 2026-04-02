//
//  XYUserEvent.swift
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

// MARK: - XYUserEvent
/// 事件
public struct XYUserEvent: XYModelDatable {
    public var id: String
    public var createTime: Date
    public var updateTime: Date?
    
    /// UID
    public let uid: String
    /// 时间
    public let time: Date
    /// 类型
    public let type: XYUserEventType
    /// 备注
    public let remark: String?
}

// MARK: - XYUserEventType
/// 事件类型
public enum XYUserEventType: Int {
    case signUp = 0     // 注册
    case signIn         // 登录
    case signOut        // 退出登录
    case cancel         // 注销账号
    case pwdSet         // 设置密码
    case pwdEdit        // 修改密码
}
