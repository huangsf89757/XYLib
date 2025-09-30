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
        return "{\(self.psm)}"
    }
}
