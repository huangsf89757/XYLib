//
//  XYCgmsSettings.swift
//  XYCgms
//
//  Created by hsf on 2025/8/27.
//

import Foundation

// MARK: - CGMS设置
public final class XYCgmsSettings {
    // MARK: var
    /// 通用设置
    public private(set) var general = XYGeneralSettings()
    /// 血糖设置
    public private(set) var glucose = XYGlucoseSettings()
    /// 提醒设置
    public private(set) var alert = XYAlertSettings()
    /// 系统设置
    public private(set) var system = XYSystemSettings()
}



/*
 XYUser
 - 用户信息
 - 账户安全
    - 修改密码
    - 注销账号
 - 注册
 - 登入
 - 登出
 - 帮助中心
 - 活动广场
 
 
 XYApp
 - 关于
 - 权限管理
    - 网络权限
    - 蓝牙权限
    - 通知权限
    - 后台App刷新开关
    - 相册权限
    - 相机权限
 - 隐私协议
 - 用户条款

 
 */


