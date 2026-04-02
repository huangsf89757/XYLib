//
//  CBService.swift
//  XYExtension
//
//  Created by hsf on 2025/8/28.
//

import Foundation
import CoreBluetooth

public extension CBService {
    var info: String {
        let dict: [String: Any] = [
            "uuid": uuid.uuidString,
            "isPrimary": isPrimary,
        ]
        return dict.toJSONString() ?? "nil"
    }
}
