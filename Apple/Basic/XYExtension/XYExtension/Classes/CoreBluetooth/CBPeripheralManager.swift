//
//  CBPeripheralManager.swift
//  XYExtension
//
//  Created by hsf on 2025/8/28.
//

import Foundation
import CoreBluetooth

public extension CBPeripheralManager {
    var info: String {
        let dict: [String: Any] = [
            "isAdvertising": isAdvertising,
        ]
        return dict.toJSONString() ?? "nil"
    }
}
