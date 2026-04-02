//
//  XYThemeProtocol.swift
//  XYApp
//
//  Created by hsf on 2025/10/19.
//

import Foundation
import SwiftUI

public protocol XYThemeProtocol {
    associatedtype T
    var light: T { get set }
    var dark: T { get set }
}
