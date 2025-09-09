//
//  XYCgmsApp.swift
//  XYCgms
//
//  Created by hsf on 2025/9/4.
//

import SwiftUI

@main
struct XYCgmsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    func test() {
#if os(iOS)
        print("xxxx")
#elseif os(watchOS)
        print("xxxx")
#endif
    }
}
