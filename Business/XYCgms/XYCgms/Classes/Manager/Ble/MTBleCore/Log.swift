//
//  Log.swift
//  Pods
//
//  Created by hsf on 2025/9/11.
//

import Foundation
import CoreBluetooth
import MTBleCore
import XYCoreBluetooth
import XYLog

extension XYCgmsBleManager {
    internal func configBleCoreLog() {
        MTBleAdapter.shared().delegate = self
        MTBleAdapter.shared().setLogLevel(.info)
    }
}

// MARK: - MTBleAdapterDelegate
extension XYCgmsBleManager: MTBleAdapterDelegate {
    public func logDidOccur(_ log: String) {
        
    }
}
