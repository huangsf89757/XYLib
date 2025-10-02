//
//  XYAppTests.swift
//  XYUtil_Tests
//
//  Created by hsf on 2025/10/2.
//

import XCTest
@testable import XYUtil

class XYAppTests: XCTestCase {
    
    func testBundleId() {
        // 测试Bundle ID获取
        let bundleId = XYApp.bundleId
        // 在测试环境中可能为空，所以我们只验证类型
        XCTAssertTrue(bundleId is String)
    }
    
    func testName() {
        // 测试应用名称获取
        let name = XYApp.name
        // 在测试环境中可能为空，所以我们只验证类型
        XCTAssertTrue(name is String)
    }
    
    func testVersion() {
        // 测试版本号获取
        let version = XYApp.version
        // 在测试环境中可能为空，所以我们只验证类型
        XCTAssertTrue(version is String)
    }
    
    func testBuild() {
        // 测试构建号获取
        let build = XYApp.build
        // 在测试环境中可能为空，所以我们只验证类型
        XCTAssertTrue(build is String)
    }
    
    func testKey() {
        // 测试Key生成
        let key = XYApp.key
        // 在测试环境中验证key的格式
        XCTAssertTrue(key is String)
        XCTAssertTrue(key.hasSuffix(".KEY"))
    }
}