//
//  CBDescriptor.swift
//  Pods
//
//  Created by hsf on 2025/9/10.
//

import Foundation
import CoreBluetooth

public extension CBDescriptor {
    var info: String {
        return "{\(uuid.uuidString)}"
    }
}

