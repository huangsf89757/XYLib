//
//  CBCentralManager.swift
//  XYExtension
//
//  Created by hsf on 2025/8/28.
//

import Foundation
import CoreBluetooth

public extension CBCentralManager {
    var info: String {
        let dict: [String: Any] = [
            "isScanning": isScanning,
            "state": state.info,
        ]
        return dict.toJSONString() ?? "nil"
    }
}
