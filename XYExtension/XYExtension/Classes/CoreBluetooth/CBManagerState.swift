//
//  CBManagerState.swift
//  MTCgmsKit
//
//  Created by hsf on 2025/8/28.
//

import Foundation
import CoreBluetooth

public extension CBManagerState {
    var info: String {
        var desc = ""
        switch self {
        case .unknown:
            desc = "unknown"
        case .resetting:
            desc = "resetting"
        case .unsupported:
            desc = "unsupported"
        case .unauthorized:
            desc = "unauthorized"
        case .poweredOff:
            desc = "poweredOff"
        case .poweredOn:
            desc = "poweredOn"
        @unknown default:
            desc = "@unknown"
        }
        return "\(desc)(\(rawValue))"
    }
}
