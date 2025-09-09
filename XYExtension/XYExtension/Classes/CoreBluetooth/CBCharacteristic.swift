//
//  CBCharacteristic.swift
//  MTCgmsKit
//
//  Created by hsf on 2025/8/28.
//

import Foundation
import CoreBluetooth

public extension CBCharacteristic {
    var info: String {
        return "{\(uuid.uuidString); \(isNotifying); \(value?.toHexString() ?? "value=nil")}"
    }
}
