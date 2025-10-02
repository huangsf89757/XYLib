//
//  XYAtomicCounterTests.swift
//  XYUtil_Tests
//
//  Created by hsf on 2025/10/2.
//

import XCTest
@testable import XYUtil

class XYAtomicCounterTests: XCTestCase {
    
    func testInitialization() {
        // 测试初始化
        let counter = XYAtomicCounter(value: 5)
        XCTAssertEqual(counter.current, 5)
    }
    
    func testDefaultInitialization() {
        // 测试默认初始化
        let counter = XYAtomicCounter()
        XCTAssertEqual(counter.current, 0)
    }
    
    func testIncrement() {
        // 测试递增
        let counter = XYAtomicCounter()
        let newValue = counter.increment()
        XCTAssertEqual(newValue, 1)
        XCTAssertEqual(counter.current, 1)
    }
    
    func testDecrement() {
        // 测试递减
        let counter = XYAtomicCounter(value: 5)
        let newValue = counter.decrement()
        XCTAssertEqual(newValue, 4)
        XCTAssertEqual(counter.current, 4)
    }
    
    func testAdd() {
        // 测试加法
        let counter = XYAtomicCounter()
        let newValue = counter.add(10)
        XCTAssertEqual(newValue, 10)
        XCTAssertEqual(counter.current, 10)
    }
    
    func testReset() {
        // 测试重置
        let counter = XYAtomicCounter(value: 5)
        let newValue = counter.reset(to: 20)
        XCTAssertEqual(newValue, 20)
        XCTAssertEqual(counter.current, 20)
    }
    
    func testDefaultReset() {
        // 测试默认重置
        let counter = XYAtomicCounter(value: 5)
        let newValue = counter.reset()
        XCTAssertEqual(newValue, 0)
        XCTAssertEqual(counter.current, 0)
    }
    
    func testThreadSafety() {
        // 测试线程安全
        let counter = XYAtomicCounter()
        
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "testQueue", attributes: .concurrent)
        
        // 启动多个并发线程进行操作
        for _ in 0..<100 {
            queue.async(group: group) {
                _ = counter.increment()
            }
        }
        
        // 等待所有操作完成
        group.wait()
        
        // 验证最终结果
        XCTAssertEqual(counter.current, 100)
    }
    
    func testMixedOperations() {
        // 测试混合操作
        let counter = XYAtomicCounter()
        
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "testQueue", attributes: .concurrent)
        
        // 启动多个并发线程进行混合操作
        for i in 0..<50 {
            queue.async(group: group) {
                if i % 2 == 0 {
                    _ = counter.increment()
                } else {
                    _ = counter.add(2)
                }
            }
        }
        
        // 等待所有操作完成
        group.wait()
        
        // 验证最终结果 (25 * 1 + 25 * 2 = 75)
        XCTAssertEqual(counter.current, 75)
    }
}