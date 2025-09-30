//
//  CBPeripheral.swift
//  MTCgmsKit
//
//  Created by hsf on 2025/8/26.
//

import Foundation
import CoreBluetooth

public extension CBPeripheral {
    var info: String {
        return "{\(identifier.uuidString); \(name ?? "name=nil"); \(state.info)}"
    }
}
