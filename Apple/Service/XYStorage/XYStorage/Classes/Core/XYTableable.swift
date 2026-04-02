//
//  XYDbTableable.swift
//  XYStorage
//
//  Created by hsf on 2026/3/19.
//

import Foundation

// MARK: - XYDbTableable
public protocol XYDbTableable {
    associatedtype ModelType
    /// 表名
    static var tableName: String { get }
    /// 将数据库实体转换为业务模型
    func toModel() -> ModelType?
    /// 从业务模型初始化数据库实体
    init(model: ModelType)
}

// MARK: - XYDbDatable
public protocol XYDbDatable {
    /// 唯一ID
    var id: String? { get set }
    /// 创建时间
    var createTime: Date? { get set }
    /// 更新时间
    var updateTime: Date? { get set }
}

// MARK: - XYModelDatable
public protocol XYModelDatable {
    /// 唯一ID
    var id: String { get set }
    /// 创建时间
    var createTime: Date { get set }
    /// 更新时间
    var updateTime: Date? { get set }
}
