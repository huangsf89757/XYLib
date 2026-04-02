//
//  XYThemeColor.swift
//  XYApp
//
//  Created by hsf on 2025/10/19.
//

import Foundation
import SwiftUI

public struct XYThemeColor: XYThemeProtocol {
    public typealias T = XYThemeColorConfig
    public var light: T
    public var dark: T
    public static let `default` = XYThemeColor(light: .default, dark: .default)
}

public struct XYThemeColorConfig {
    public let accent: Color
    public let primary: Color
    public let secondary: Color
    public static let `default` = XYThemeColorConfig(accent: .accentColor, primary: .primary, secondary: .secondary)
}
