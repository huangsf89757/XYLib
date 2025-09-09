//
//  CBService.swift
//  MTCgmsKit
//
//  Created by hsf on 2025/8/28.
//

import Foundation
import CoreBluetooth

public extension CBService {
    var info: String {
        return "{\(uuid.uuidString); \(isPrimary)}"
    }
}
