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
        XCTAssertFalse(bundleId.isEmpty, "Bundle ID should not be empty")
    }
    
    func testName() {
        // 测试应用名称获取
        let name = XYApp.name
        XCTAssertFalse(name.isEmpty, "App name should not be empty")
    }
    
    func testVersion() {
        // 测试版本号获取
        let version = XYApp.version
        XCTAssertFalse(version.isEmpty, "Version should not be empty")
    }
    
    func testBuild() {
        // 测试构建号获取
        let build = XYApp.build
        XCTAssertFalse(build.isEmpty, "Build number should not be empty")
    }
    
    func testKey() {
        // 测试Key生成
        let key = XYApp.key
        let bundleId = XYApp.bundleId
        XCTAssertTrue(key.hasPrefix(bundleId), "Key should start with bundle ID")
        XCTAssertTrue(key.hasSuffix(".KEY"), "Key should end with .KEY")
    }
}