//
//  XYCgms.swift
//  XYCgms
//
//  Created by hsf on 2025/8/26.
//

// MARK: - Import
// System
import Foundation
// Basic
// Server
// Tool
// Business
// Third


// MARK: - XYCgms
/// 血糖数据
public final class XYCgms: Identifiable {
    // MARK: var
    public var id: String = UUID().uuidString
    /// 血糖值（原始值）
    public var rawValue: XYCgmsValue
    /// 血糖值（平滑值）
    public var smoothValue: XYCgmsValue?

    /// 血糖趋势
    private var trendValue: Float?
    public var trend: XYCgmsTrend? {
        guard let trendValue else { return nil }
        return  XYCgmsTrend(value: trendValue)
    }
    
    // MARK: life cycle
    public init(rawValue: XYCgmsValue, trendValue: Float?) {
        self.rawValue = rawValue
        self.trendValue = trendValue
    }
    
}

