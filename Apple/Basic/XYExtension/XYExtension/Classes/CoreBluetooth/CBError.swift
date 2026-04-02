//
//  CBError.swift
//  Pods
//
//  Created by hsf on 2025/9/15.
//

import Foundation
import CoreBluetooth

public extension CBError.Code {
    var info: String {
        var desc = ""
        switch self {
        case .unknown:
            desc = "unknown"
        case .invalidParameters:
            desc = "invalidParameters"
        case .invalidHandle:
            desc = "invalidHandle"
        case .notConnected:
            desc = "notConnected"
        case .outOfSpace:
            desc = "outOfSpace"
        case .operationCancelled:
            desc = "operationCancelled"
        case .connectionTimeout:
            desc = "connectionTimeout"
        case .peripheralDisconnected:
            desc = "peripheralDisconnected"
        case .uuidNotAllowed:
            desc = "uuidNotAllowed"
        case .alreadyAdvertising:
            desc = "alreadyAdvertising"
        case .connectionFailed:
            desc = "connectionFailed"
        case .connectionLimitReached:
            desc = "connectionLimitReached"
        case .unkownDevice:
            desc = "unkownDevice"
        case .operationNotSupported:
            desc = "operationNotSupported"
        case .peerRemovedPairingInformation:
            desc = "peerRemovedPairingInformation"
        case .encryptionTimedOut:
            desc = "encryptionTimedOut"
        case .tooManyLEPairedDevices:
            desc = "tooManyLEPairedDevices"
        @unknown default:
            desc = "@unknown"
        }
        return "\(desc)(\(rawValue))"
    }
}

public extension Error {
    var info: String {
        if let error = self as? CBError {
            return error.code.info
        }
        return localizedDescription
    }
}
