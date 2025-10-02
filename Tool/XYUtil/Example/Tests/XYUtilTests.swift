//
//  XYUtilTests.swift
//  XYUtil_Tests
//
//  Created by hsf on 2025/10/2.
//

import XCTest
@testable import XYUtil

class XYUtilTests: XCTestCase {
    
    func testXYIdentifierType() {
        // 测试XYIdentifier类型别名
        let identifier: XYIdentifier = "test_identifier"
        XCTAssertEqual(identifier, "test_identifier")
        XCTAssertTrue(identifier is String)
    }
    
    func testXYIdentifierUsage() {
        // 测试XYIdentifier在实际使用中的表现
        func processIdentifier(_ id: XYIdentifier) -> String {
            return "Processed: \(id)"
        }
        
        let testId: XYIdentifier = "user_123"
        let result = processIdentifier(testId)
        XCTAssertEqual(result, "Processed: user_123")
    }
}