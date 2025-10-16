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
open class XYCentral: NSObject {
    public private(set) var central: CBCentral

    public init(central: CBCentral) {
        self.central = central
        super.init()
        XYBleLog.debug(params:[
            "central": central.info,
        ])
    }

    /// 最大并发连接数（iOS 6.0+）
    open var maximumUpdateValueLength: Int { central.maximumUpdateValueLength }

}



