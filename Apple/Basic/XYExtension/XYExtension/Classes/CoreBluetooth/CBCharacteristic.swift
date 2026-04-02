//
//  CBCharacteristic.swift
//  XYExtension
//
//  Created by hsf on 2025/8/28.
//

import Foundation
import CoreBluetooth

public extension CBCharacteristic {
    var info: String {
        let dict: [String: Any] = [
            "uuid": uuid.uuidString,
            "isNotifying": isNotifying,
            "value": value?.toHexString() ?? "nil"
        ]
        return dict.toJSONString() ?? "nil"
    }
}
