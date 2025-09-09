//
//  XYCgmsApp.swift
//  XYCgms
//
//  Created by hsf on 2025/9/4.
//

import SwiftUI
import XYLog

@main
struct XYCgmsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear(perform: test)
        }
    }
    
    func test() {
        XYLog.enable = true
#if os(iOS)
        XYLog.info(id: UUID(), tag: ["BLE", "CentralManager"], process: .begin, content: "startScan", "1", "sfajo")
        XYLog.info(id: UUID(), tag: ["BLE", "CentralManager"], process: .doing, content: "scaning", "2", "gfsdgf")
        XYLog.verbose(id: UUID(), tag: ["BLE", "CentralManager"], process: .succ, content: "scanSuccess", "3", "653ewdv")
        XYLog.debug(id: UUID(), tag: ["BLE", "CentralManager"], process: .succ, content: "scanSuccess", "3", "653ewdv")
        XYLog.info(id: UUID(), tag: ["BLE", "CentralManager"], process: .succ, content: "scanSuccess", "3", "653ewdv")
        XYLog.warning(id: UUID(), tag: ["BLE", "CentralManager"], process: .succ, content: "scanSuccess", "3", "653ewdv")
        XYLog.error(id: UUID(), tag: ["BLE", "CentralManager"], process: .succ, content: "scanSuccess", "3", "653ewdv")
        XYLog.fatal(id: UUID(), tag: ["BLE", "CentralManager"], process: .succ, content: "scanSuccess", "3", "653ewdv")
#elseif os(watchOS)
        print("xxxx")
#endif
    }
}
