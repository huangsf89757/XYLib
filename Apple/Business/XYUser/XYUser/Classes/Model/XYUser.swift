//
//  XYUser.swift
//  XYUser
//
//  Created by hsf on 2026/3/18.
//

import Foundation

// MARK: - XYUser
/// 用户
open class XYUser {
    /// 账号信息
    public let account: XYUserAccount
    /// 基础信息
    public var information: XYUserInfomation?
    /// 授权信息
    public var authorizations: [XYUserAuthorization] = []
    
    // MARK: life cycle
    public init(account: XYUserAccount) {
        self.account = account
    }
}
