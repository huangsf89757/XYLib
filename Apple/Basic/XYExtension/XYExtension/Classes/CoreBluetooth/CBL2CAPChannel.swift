//
//  CBL2CAPChannel.swift
//  Pods
//
//  Created by hsf on 2025/9/10.
//

import Foundation
import CoreBluetooth

public extension CBL2CAPChannel {
    var info: String {
        let dict: [String: Any] = [
            "uuid": psm.description,
        ]
        return dict.toJSONString() ?? "nil"
    }
}
