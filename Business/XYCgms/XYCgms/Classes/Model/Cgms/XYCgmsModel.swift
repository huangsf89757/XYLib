//
//  XYCgmsModel.swift
//  XYCgms
//
//  Created by hsf on 2025/8/26.
//

import Foundation

// MARK: - 血糖数据
public final class XYCgmsModel {
    // MARK: var
    /// 血糖基准值
    public var value: XYCgmsValue
    /// 血糖趋势
    public var trendValue: Float?
    public var trend: XYCgmsTrend? {
        guard let trendValue else { return nil }
        return  XYCgmsTrend(value: trendValue)
    }
    
    // MARK: init
    public init(value: XYCgmsValue, trendValue: Float?) {
        self.value = value
        self.trendValue = trendValue
    }
    
}

