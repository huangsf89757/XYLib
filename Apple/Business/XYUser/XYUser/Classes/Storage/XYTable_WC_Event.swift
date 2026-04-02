//
//  XYTable_WC_Event.swift
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

// MARK: - XYTable_WC_Event
public final class XYTable_WC_Event: XYDbDatable {
    public init() {}
    public var id: String?
    public var createTime: Date?
    public var updateTime: Date?
    
    /// UID
    public var uid: String?
    /// 时间
    public var time: Date?
    /// 类型
    public var type: Int?
    /// 备注
    public var remark: String?
}

// MARK: - WCDBSwift.TableCodable
extension XYTable_WC_Event: WCDBSwift.TableCodable {
    public enum CodingKeys: String, CodingTableKey {
        public typealias Root = XYTable_WC_Event

        case id
        case createTime
        case updateTime
        
        case uid
        case time
        case type
        case remark
        
        public static var objectRelationalMapping = TableBinding(CodingKeys.self) {
            BindColumnConstraint(uid, isPrimary: true, isUnique: true)
        }
    }
}

// MARK: - XYDbTableable
extension XYTable_WC_Event: XYDbTableable {
    public typealias ModelType = XYUserEvent
    
    public static var tableName: String { "event" }
    
    public func toModel() -> ModelType? {
        guard let id,
              let createTime else {
            return nil
        }
        guard let uid,
              let time,
              let type, let typeEnum = XYUserEventType(rawValue: type) else {
            return nil
        }
        let model = ModelType(id: id,
                              createTime: createTime,
                              updateTime: updateTime,
                              uid: uid,
                              time: time,
                              type: typeEnum,
                              remark: remark)
        return model
    }
    
    public convenience init(model: ModelType) {
        self.init()
        id = model.id
        createTime = model.createTime
        updateTime = model.updateTime
        uid = model.uid
        time = model.time
        type = model.type.rawValue
        remark = model.remark
    }
}

