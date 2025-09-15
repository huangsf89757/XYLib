//
//  XYCgmsBleManager.swift
//  Pods
//
//  Created by hsf on 2025/9/10.
//

import Foundation
import CoreBluetooth
import XYCoreBluetooth
import MTBleCore

public final class XYCgmsBleManager: NSObject {
    // MARK: shared
    public static let shared = XYCgmsBleManager()
    private override init() {
        super.init()
        XYCentralManagerAgent.shared.plugins = [self]
    }
    
    // MARK: log
    public static let logTag = "Cgms.Ble"
    
    // MARK: uuid
    static let serviceUuid181F = "181F"
    static let characteristicUuidF001 = "F001"
    static let characteristicUuidF002 = "F002"
    static let characteristicUuidF003 = "F003"
    static let characteristicUuidF005 = "F005"
    
    
}


extension XYCgmsBleManager {
    
}
