//
//  XYTable_WC_Authorization.swift
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

// MARK: - XYTable_WC_Authorization
public final class XYTable_WC_Authorization: XYDbDatable {
    public init() {}
    public var id: String?
    public var createTime: Date?
    public var updateTime: Date?
    
    /// UID
    public var uid: String?
    /// 授权类型
    public var type: Int?
    /// 认证信息
    public var info: String?
}

// MARK: - WCDBSwift.TableCodable
extension XYTable_WC_Authorization: WCDBSwift.TableCodable {
    public enum CodingKeys: String, CodingTableKey {
        public typealias Root = XYTable_WC_Authorization

        case id
        case createTime
        case updateTime
        
        case uid
        case type
        case info
        
        public static var objectRelationalMapping = TableBinding(CodingKeys.self) {
            BindColumnConstraint(uid, isPrimary: true, isUnique: true)
        }
    }
}

// MARK: - XYDbTableable
extension XYTable_WC_Authorization: XYDbTableable {
    public typealias ModelType = XYUserAuthorization
    
    public static var tableName: String { "authorization" }
    
    public func toModel() -> ModelType? {
        guard let id,
              let createTime else {
            return nil
        }
        guard let uid,
              let type, let typeEnum = XYUserAuthType(rawValue: type),
              let info else {
            return nil
        }
        let model = ModelType(id: id,
                              createTime: createTime,
                              updateTime: updateTime,
                              uid: uid,
                              type: typeEnum,
                              info: info)
        return model
    }
    
    public convenience init(model: ModelType) {
        self.init()
        id = model.id
        createTime = model.createTime
        updateTime = model.updateTime
        uid = model.uid
        type = model.type.rawValue
        info = model.info
    }
}
