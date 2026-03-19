//
//  XYCentral.swift
//  XYCoreBluetooth
//
//  Created by hsf on 2025/10/16.
//

// Module: System
import Foundation
import CoreBluetooth
// Module: Basic
import XYExtension
// Module: Server
import XYLog
// Module: Tool
import XYUtil
// Module: Business
// Module: Third

// MARK: - XYCentral
/// 对 CBCentral 的轻量包装（注意：非 CBCentralManager），转发只读属性与辅助日志
/// 
/// 该类提供对蓝牙中心设备(CBCentral)的包装，主要用于外设模式下，
/// 对外设管理器收到的中心设备进行统一处理和日志记录。
open class XYCentral: NSObject {
    // MARK: - Properties
    /// 系统中心设备对象
    public private(set) var central: CBCentral
    
    /// 最大可更新值长度（iOS 6.0+）
    ///
    /// 表示可以发送给此中心设备的特征值的最大长度，
    /// 用于确定更新特征值时数据的分块策略。
    open var maximumUpdateValueLength: Int { central.maximumUpdateValueLength }

    // MARK: - Life Cycle
    /// 初始化中心设备包装类
    /// - Parameter central: 系统中心设备对象
    public init(central: CBCentral) {
        self.central = central
        super.init()
        XYBleLog.debug(params:[
            "central": central.info,
        ])
    }

}



