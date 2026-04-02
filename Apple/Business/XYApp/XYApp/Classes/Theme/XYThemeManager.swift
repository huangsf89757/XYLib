////
////  XYThemeManager.swift
////  XYApp
////
////  Created by hsf on 2025/10/19.
////
//
//import Foundation
//import SwiftUI
//
//import XYUtil
//
//public class XYThemeManager: ObservableObject {
//    // MARK: shared
//    public static let shared = XYThemeManager()
//    private init() {}
//
//    // MARK: var
//    @AppStorage(XYKey.generate(with: ["Theme", "CurrentId"]))
//    public var currentThemeId: String = "default"
//
//    @Published public var availableThemes: [XYTheme] = [.default]
//
//    public var currentTheme: XYTheme {
//        availableThemes.first { $0.id == currentThemeId } ?? .default
//    }
//
//}
//
//// MARK: - switch
//public extension XYThemeManager {
//    func `switch`(to id: String) {
//        if availableThemes.contains(where: { $0.id == id }) {
//            currentThemeId = id
//        } else {
//            print("⚠️ 主题不存在: $id)")
//        }
//    }
//}
//
//// MARK: - 增删改查
//public extension XYThemeManager {
//    func add(_ theme: XYTheme) {
//        
//    }
//}
//
