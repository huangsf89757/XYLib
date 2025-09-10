//
//  XYApp.swift
//  XYUtil
//
//  Created by hsf on 2025/9/4.
//

import Foundation
import UIKit

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
    
    /// App Icon
    public static var logo: UIImage? {
        let info = Bundle.main.localizedInfoDictionary ?? [:]
        guard let icons = info["CFBundleIcons"] as? [String: Any],
              let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
              let iconFiles = primaryIcon["CFBundleIconFiles"] as? NSArray,
              let lastIcon = iconFiles.lastObject as? String,
              let icon = UIImage(named: lastIcon)
        else { return nil }
        return icon
    }
}

public extension XYApp {
    static var key: String {
        bundleId + ".KEY"
    }
}
