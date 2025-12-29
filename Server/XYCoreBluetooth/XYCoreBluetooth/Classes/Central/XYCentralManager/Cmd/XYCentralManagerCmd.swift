//
//  XYCentralManagerCmd.swift
//  XYCoreBluetooth
//
//  Created by hsf on 2025/12/22.
//

// MARK: - Import
// System
import Foundation
import CoreBluetooth
// Basic
import XYExtension
// Server
import XYLog
// Tool
import XYUtil
import XYCmd
// Business
// Third


// MARK: - XYCentralManagerCmd
open class XYCentralManagerCmd<ResultType>: XYCmd<ResultType> {
    // MARK: var
    public let centralManagerWrapper: XYCentralManagerWrapper
    weak var oldDelegate: (any XYCentralManagerWrapperDelegate)?
    
    // MARK: life cycle
    public init(
        id: String = UUID().uuidString,
        timeout: TimeInterval = 5,
        maxRetries: Int? = 1,
        retryDelay: TimeInterval? = 1.0,
        centralManagerWrapper: XYCentralManagerWrapper,
    ) {
        self.centralManagerWrapper = centralManagerWrapper
        self.oldDelegate = centralManagerWrapper.delegate
        super.init(id: id, timeout: timeout, maxRetries: maxRetries, retryDelay: retryDelay)
        self.logTag = ["XYCmd", "Ble", "CM"]
    }
}


