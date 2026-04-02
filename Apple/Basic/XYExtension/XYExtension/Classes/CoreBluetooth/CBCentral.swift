//
//  CBCentral.swift
//  XYExtension
//
//  Created by hsf on 2025/8/28.
//

import Foundation
import CoreBluetooth

public extension CBCentral {
    var info: String {
        let dict: [String: Any] = [
            "maximumUpdateValueLength": maximumUpdateValueLength,
        ]
        return dict.toJSONString() ?? "nil"
    }
}
