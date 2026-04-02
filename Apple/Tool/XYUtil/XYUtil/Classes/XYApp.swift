//
//  XYApp.swift
//  XYApp
//
//  Created by hsf on 2025/9/4.
//

import Foundation

public final class XYApp {
    ///App Bundle Id
    public static var bundleId: String {
        get {
            let info = Bundle.main.localizedInfoDictionary ?? [:]
            return info["CFBundleIdentifier"] as? String ?? ""
        }
    }
    
    ///App Name
    public static var name: String {
        get {
            let info = Bundle.main.localizedInfoDictionary ?? [:]
            return info["CFBundleDisplayName"] as? String ?? ""
        }
    }
    
    ///App Version Num
    public static var version: String {
        get {
            let info = Bundle.main.localizedInfoDictionary ?? [:]
            return info["CFBundleShortVersionString"] as? String ?? ""
        }
    }
    
    ///App Build Num
    public static var build: String {
        get {
            let info = Bundle.main.localizedInfoDictionary ?? [:]
            return info["CFBundleVersion"] as? String ?? ""
        }
    }
}

public extension XYApp {
    static var key: String {
        bundleId + ".KEY"
    }
}


public struct XYKey {
    public static func generate(with component: [String], separator: String = ".") -> String {
        return "XY" + separator + component.joined(separator: separator)
    }
}
