//
//  XYTable_WC_Account.swift
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

// MARK: - XYTable_WC_Account
public final class XYTable_WC_Account: XYDbDatable {
    public init() {}
    public var id: String?
    public var createTime: Date?
    public var updateTime: Date?
    
    /// 账户编码
    public var no: String?
    /// 账户身份
    public var role: Int?
    /// 账户密码
    public var pwd: String?
}

// MARK: - WCDBSwift.TableCodable
extension XYTable_WC_Account: WCDBSwift.TableCodable {
    public enum CodingKeys: String, CodingTableKey {
        public typealias Root = XYTable_WC_Account

        case id
        case createTime
        case updateTime
        
        case no
        case role
        case pwd
        
        public static var objectRelationalMapping = TableBinding(CodingKeys.self) {
            BindColumnConstraint(id, isPrimary: true, isUnique: true)
        }
    }
}

// MARK: - XYDbTableable
extension XYTable_WC_Account: XYDbTableable {
    public typealias ModelType = XYUserAccount
    
    public static var tableName: String { "account" }
    
    public func toModel() -> ModelType? {
        guard let id,
              let createTime else {
            return nil
        }
        guard let no,
              let role, let roleEnum = XYUserRole(rawValue: role),
              let pwd else {
            return nil
        }
        let model = ModelType(id: id,
                              createTime: createTime,
                              updateTime: updateTime,
                              no: no,
                              role: roleEnum,
                              pwd: pwd)
        return model
    }
    
    public convenience init(model: ModelType) {
        self.init()
        id = model.id
        createTime = model.createTime
        updateTime = model.updateTime
        no = model.no
        role = model.role.rawValue
        pwd = model.pwd
    }
}
