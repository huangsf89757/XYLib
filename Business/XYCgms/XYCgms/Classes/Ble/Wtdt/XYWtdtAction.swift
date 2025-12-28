//
//  XYWtdtAction.swift
//  XYCgms
//
//  Created by hsf on 2025/12/18.
//

// MARK: - Import
// System
import Foundation
import CoreBluetooth
// Basic
import XYExtension
// Server
import XYCoreBluetooth
import XYLog
// Tool
// Business
// Third
import MTBleCore


// MARK: - XYWtdtAction
/// 微泰动态CGMS操作
public class XYWtdtAction {
    // MARK: ActionType
    public enum ActionType {
        // MARK: 配对/解配
        /// 配对
        case pair
        /// 解配
        case unpair
        
        // MARK: 升级
        /// 固件升级
        case ota
        /// 默认参数升级
        case dpu
        
        // MARK: 其他
        /// 激活
        case activate
        /// 血糖校准
        case calibrate
        
        // MARK: 数据同步
        /// 同步基础血糖数据
        case syncBasicData
        /// 同步原始血糖数据
        case syncRawData
        /// 同步血糖校准数据
        case syncCalData
        /// 同步设备日志数据
        case syncLogData

        
//        var items: XYWtdtActionItem {
//            switch self {
//            case .pair:
//                <#code#>
//            case .unpair:
//                <#code#>
//            case .ota:
//                <#code#>
//            case .dpu:
//                <#code#>
//            case .activate:
//                <#code#>
//            case .calibrate:
//                <#code#>
//            case .syncBasicData:
//                <#code#>
//            case .syncRawData:
//                <#code#>
//            case .syncCalData:
//                <#code#>
//            case .syncLogData:
//                <#code#>
//            }
//        }
    }
    
    /*
     - scan
     - discover
     - connect
     - pair
        - write
     - setStatus
     - setMode
     -
     */
    
}



// MARK: - XYWtdtActionItem
public class XYWtdtActionItem {
    /// 指令
    public let cmd: XYWtdtCmd
    /// 是否必须
    public let isRequired: Bool
    /// 父节点
    public weak var prev: XYWtdtActionItem?
    /// 子节点
    public var next: XYWtdtActionItem?
    
    public init(cmd: XYWtdtCmd, isRequired: Bool, prev: XYWtdtActionItem? = nil, next: XYWtdtActionItem? = nil) {
        self.cmd = cmd
        self.isRequired = isRequired
        self.prev = prev
        self.next = next
    }
}
