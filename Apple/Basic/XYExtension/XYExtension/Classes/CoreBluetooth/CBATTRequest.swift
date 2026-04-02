//
//  CBATTRequest.swift
//  XYExtension
//
//  Created by hsf on 2025/8/28.
//

import Foundation
import CoreBluetooth

public extension CBATTRequest {
    var info: String {
        let dict: [String: Any] = [
            "offset": offset,
            "value": value?.toHexString() ?? "nil",
        ]
        return dict.toJSONString() ?? "nil"
    }
}
