//
//  CBCharacteristicProperties.swift
//  Pods
//
//  Created by hsf on 2025/9/10.
//

import Foundation
import CoreBluetooth

public extension CBCharacteristicProperties {
    var canSubscribe: Bool {
        contains(.notify) || contains(.indicate)
    }
}
