//
//  AppDelegate.swift
//  XYCoreBluetooth
//
//  Created by hsf89757 on 09/10/2025.
//  Copyright (c) 2025 hsf89757. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 设置应用程序的根视图控制器
        window = UIWindow(frame: UIScreen.main.bounds)
        
        // 创建主视图控制器并设置为根视图
        let mainViewController = MainViewController()
        let navigationController = UINavigationController(rootViewController: mainViewController)
        window?.rootViewController = navigationController
        
        // 显示窗口
        window?.makeKeyAndVisible()
        
        return true
    }
}

