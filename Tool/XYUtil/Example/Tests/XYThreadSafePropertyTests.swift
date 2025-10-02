//
//  XYThreadSafePropertyTests.swift
//  XYUtil_Tests
//
//  Created by hsf on 2025/10/2.
//

import XCTest
@testable import XYUtil

class XYThreadSafePropertyTests: XCTestCase {
    
    func testInitialization() {
        // 测试初始化
        @XYThreadSafeProperty var value: Int = 10
        XCTAssertEqual(_value.wrappedValue, 10)
    }
    
    func testValueAssignment() {
        // 测试值赋值
        @XYThreadSafeProperty var value: String = "initial"
        XCTAssertEqual(_value.wrappedValue, "initial")
        
        _value.wrappedValue = "updated"
        XCTAssertEqual(_value.wrappedValue, "updated")
    }
    
    func testThreadSafety() {
        // 测试线程安全
        @XYThreadSafeProperty var counter: Int = 0
        
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "testQueue", attributes: .concurrent)
        
        // 启动多个并发线程进行操作
        for _ in 0..<100 {
            queue.async(group: group) {
                _counter.wrappedValue += 1
            }
        }
        
        // 等待所有操作完成
        group.wait()
        
        // 验证最终结果
        XCTAssertEqual(_counter.wrappedValue, 100)
    }
    
    func testWithLock() {
        // 测试withLock方法
        @XYThreadSafeProperty var value: Int = 5
        
        let result = _value.withLock { value in
            value *= 2
            return value
        }
        
        XCTAssertEqual(result, 10)
        XCTAssertEqual(_value.wrappedValue, 10)
    }
    
    func testRead() {
        // 测试read方法
        @XYThreadSafeProperty var value: [Int] = [1, 2, 3]
        
        let count = _value.read { $0.count }
        XCTAssertEqual(count, 3)
        
        let isEmpty = _value.read { $0.isEmpty }
        XCTAssertFalse(isEmpty)
    }
}