//
//  XYUserAccount.swift
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

// MARK: - XYUserAccount
/// 账户信息
public struct XYUserAccount: XYModelDatable {
    public var id: String
    public var createTime: Date
    public var updateTime: Date?
    
    /// 编码
    public let no: String
    /// 身份
    public var role: XYUserRole
    /// 密码
    public var pwd: String
}

// MARK: - XYUserRole
/// 身份
public enum XYUserRole: Int {
    case superAdmin = 0     // 超级管理员
    case admin              // 管理员
    case `internal`         // 内部成员
    case betaTest           // 内测用户
    case publicTest         // 外测用户
    case tourist            // 游客用户
    case normal             // 普通用户
    case custom             // 定制用户
}
