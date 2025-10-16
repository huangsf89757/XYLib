//
//  CBPeripheral.swift
//  XYExtension
//
//  Created by hsf on 2025/8/26.
//

import Foundation
import CoreBluetooth

public extension CBPeripheral {
    var info: String {
        let dict: [String: Any] = [
            "identifier": identifier.uuidString,
            "name": name ?? "nil",
            "state": state.info,
        ]
        return dict.toJSONString() ?? "nil"
    }
}
