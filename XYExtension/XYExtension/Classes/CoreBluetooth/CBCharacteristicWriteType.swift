//
//  CBCharacteristicWriteType.swift
//  Pods
//
//  Created by hsf on 2025/9/10.
//

import Foundation
import CoreBluetooth

public extension CBCharacteristicWriteType {
    var info: String {
        var desc = ""
        switch self {
        case .withResponse:
            desc = "withResponse"
        case .withoutResponse:
            desc = "withoutResponse"
        @unknown default:
            desc = "@unknown"
        }
        return "\(rawValue)(\(desc))"
    }
}
