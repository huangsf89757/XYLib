//
//  CBPeripheralState.swift
//  XYExtension
//
//  Created by hsf on 2025/8/28.
//

import Foundation
import CoreBluetooth

public extension CBPeripheralState {
    var info: String {
        var desc = ""
        switch self {
        case .disconnected:
            desc = "disconnected"
        case .connecting:
            desc = "connecting"
        case .connected:
            desc = "connected"
        case .disconnecting:
            desc = "disconnecting"
        @unknown default:
            desc = "@unknown"
        }
        return "\(desc)(\(rawValue))"
    }
}
