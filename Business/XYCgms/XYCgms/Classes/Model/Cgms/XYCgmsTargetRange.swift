//
//  XYCgmsTargetRange.swift
//  XYCgms
//
//  Created by hsf on 2025/8/28.
//

import Foundation

// MARK: - 血糖目标范围
public final class XYCgmsTargetRange {
    // MARK: var
    public var high: XYCgmsValue
    public var low: XYCgmsValue
    
    // MARK: init
    public init(high: XYCgmsValue, low: XYCgmsValue) {
        self.high = high
        self.low = low
    }
}
