//
//  XYTable_WC_Information.swift
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
import WCDBSwift

// MARK: - XYTable_WC_Information
public final class XYTable_WC_Information: XYDbDatable {
    public init() {}
    public var id: String?
    public var createTime: Date?
    public var updateTime: Date?
    
    /// UID
    public var uid: String?
    /// 手机号
    public var phone: String?
    /// 邮箱号
    public var email: String?
    /// 用户名
    public var name: String?
    /// 性别
    public var gender: Int?
    /// 身高
    public var height: Float?
    /// 体重
    public var weight: Float?
    /// 出生日期
    public var birthday: Date?
}

// MARK: - WCDBSwift.TableCodable
extension XYTable_WC_Information: WCDBSwift.TableCodable {
    public enum CodingKeys: String, CodingTableKey {
        public typealias Root = XYTable_WC_Information

        case id
        case createTime
        case updateTime
        
        case uid
        case phone
        case email
        case name
        case gender
        case height
        case weight
        case birthday
        
        public static var objectRelationalMapping = TableBinding(CodingKeys.self) {
            BindColumnConstraint(uid, isPrimary: true, isUnique: true)
        }
    }
}

// MARK: - XYDbTableable
extension XYTable_WC_Information: XYDbTableable {
    public typealias ModelType = XYUserInfomation
    
    public static var tableName: String { "information" }
    
    public func toModel() -> ModelType? {
        guard let id,
              let createTime else {
            return nil
        }
        guard let uid else {
            return nil
        }
        var model = ModelType(id: id,
                              createTime: createTime,
                              updateTime: updateTime,
                              uid: uid)
        model.phone = phone
        model.email = email
        model.name = name
        if let gender, let genderEnum = XYUserGender(rawValue: gender) {
            model.gender = genderEnum
        }
        model.height = height
        model.weight = weight
        model.birthday = birthday
        return model
    }
    
    public convenience init(model: ModelType) {
        self.init()
        id = model.id
        createTime = model.createTime
        updateTime = model.updateTime
        uid = model.uid
        phone = model.phone
        email = model.email
        name = model.name
        gender = model.gender?.rawValue
        height = model.height
        weight = model.weight
        birthday = model.birthday
    }
}

