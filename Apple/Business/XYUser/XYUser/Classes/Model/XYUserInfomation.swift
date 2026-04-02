//
//  XYUserInfomation.swift
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

// MARK: - XYUserInfomation
/// 用户信息
public struct XYUserInfomation: XYModelDatable {
    public var id: String
    public var createTime: Date
    public var updateTime: Date?
    
    /// UID
    public let uid: String
    /// 手机号
    public var phone: String?
    /// 邮箱号
    public var email: String?
    /// 用户名
    public var name: String?
    /// 性别
    public var gender: XYUserGender?
    /// 身高
    public var height: Float?
    /// 体重
    public var weight: Float?
    /// BMI
    public var bmi: Float? {
        guard let height = height, let weight = weight else { return nil }
        if height <= 0 { return nil }
        return weight / (height * height)
    }
    /// 出生日期
    public var birthday: Date?
    /// 年龄
    public var age: Int? {
        guard let birthday = birthday else { return nil }
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year], from: birthday, to: now)
        return components.year
    }
}

// MARK: - XYUserGender
/// 性别
public enum XYUserGender: Int {
    case unknown = 0    // 未知
    case male           // 男
    case female         // 女
}
