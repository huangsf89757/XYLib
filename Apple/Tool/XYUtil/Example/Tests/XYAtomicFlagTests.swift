//
//  XYAtomicFlagTests.swift
//  XYUtil_Tests
//
//  Created by hsf on 2025/10/2.
//

import XCTest
@testable import XYUtil

class XYAtomicFlagTests: XCTestCase {
    
    func testInitialization() {
        // 测试初始化
        let flag = XYAtomicFlag(value: true)
        XCTAssertTrue(flag.isSet)
    }
    
    func testDefaultInitialization() {
        // 测试默认初始化
        let flag = XYAtomicFlag()
        XCTAssertFalse(flag.isSet)
    }
    
    func testSet() {
        // 测试设置
        let flag = XYAtomicFlag()
        XCTAssertFalse(flag.isSet)
        
        let result = flag.set()
        XCTAssertTrue(result)
        XCTAssertTrue(flag.isSet)
    }
    
    func testReset() {
        // 测试重置
        let flag = XYAtomicFlag(value: true)
        XCTAssertTrue(flag.isSet)
        
        let result = flag.reset()
        XCTAssertFalse(result)
        XCTAssertFalse(flag.isSet)
    }
    
    func testToggle() {
        // 测试切换
        let flag = XYAtomicFlag()
        XCTAssertFalse(flag.isSet)
        
        let result1 = flag.toggle()
        XCTAssertTrue(result1)
        XCTAssertTrue(flag.isSet)
        
        let result2 = flag.toggle()
        XCTAssertFalse(result2)
        XCTAssertFalse(flag.isSet)
    }
    
    func testCompareAndSetSuccess() {
        // 测试比较并设置成功
        let flag = XYAtomicFlag()
        XCTAssertFalse(flag.isSet)
        
        let success = flag.compareAndSet(expected: false, newValue: true)
        XCTAssertTrue(success)
        XCTAssertTrue(flag.isSet)
    }
    
    func testCompareAndSetFailure() {
        // 测试比较并设置失败
        let flag = XYAtomicFlag(value: true)
        XCTAssertTrue(flag.isSet)
        
        let success = flag.compareAndSet(expected: false, newValue: true)
        XCTAssertFalse(success)
        XCTAssertTrue(flag.isSet) // 值应该保持不变
    }
    
    func testThreadSafety() {
        // 测试线程安全
        let flag = XYAtomicFlag()
        
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "testQueue", attributes: .concurrent)
        
        var setCount = 0
        var resetCount = 0
        
        let setCountQueue = DispatchQueue(label: "setCountQueue")
        let resetCountQueue = DispatchQueue(label: "resetCountQueue")
        
        // 启动多个并发线程进行设置操作
        for _ in 0..<100 {
            queue.async(group: group) {
                if flag.compareAndSet(expected: false, newValue: true) {
                    setCountQueue.sync {
                        setCount += 1
                    }
                }
            }
        }
        
        // 等待所有设置操作完成
        group.wait()
        
        // 启动多个并发线程进行重置操作
        for _ in 0..<100 {
            queue.async(group: group) {
                if flag.compareAndSet(expected: true, newValue: false) {
                    resetCountQueue.sync {
                        resetCount += 1
                    }
                }
            }
        }
        
        // 等待所有重置操作完成
        group.wait()
        
        // 验证结果
        XCTAssertEqual(setCount, 1)  // 只有第一次设置应该成功
        XCTAssertEqual(resetCount, 1)  // 只有第一次重置应该成功
        XCTAssertFalse(flag.isSet)  // 最终状态应该是false
    }
}