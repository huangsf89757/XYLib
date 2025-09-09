//
//  WCSessionActivationState.swift
//  MTCgmsKit
//
//  Created by hsf on 2025/8/28.
//

import Foundation
import WatchConnectivity

#if os(iOS) || os(watchOS)
public extension WCSessionActivationState {
    var info: String {
        var desc = ""
        switch self {
        case .notActivated:
            desc = "notActivated"
        case .inactive:
            desc = "inactive"
        case .activated:
            desc = "activated"
        @unknown default:
            desc = "@unknown"
        }
        return "\(rawValue)(\(desc))"
    }
}
#endif
