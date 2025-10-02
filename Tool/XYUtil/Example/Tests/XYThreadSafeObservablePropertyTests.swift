//
//  XYThreadSafeObservablePropertyTests.swift
//  XYUtil_Tests
//
//  Created by hsf on 2025/10/2.
//

import XCTest
@testable import XYUtil

class XYThreadSafeObservablePropertyTests: XCTestCase {
    
    func testInitialization() {
        // 测试初始化
        @XYThreadSafeObservableProperty var value: String = "initial"
        XCTAssertEqual(_value.wrappedValue, "initial")
    }
    
    func testObserverNotification() {
        // 测试观察者通知
        @XYThreadSafeObservableProperty var value: Int = 0
        
        let expectation = self.expectation(description: "Observer called")
        var observed = false
        var observedOldValue: Int?
        var observedNewValue: Int?
        
        _value.addObserver { oldValue, newValue in
            observed = true
            observedOldValue = oldValue
            observedNewValue = newValue
            expectation.fulfill()
        }
        
        _value.wrappedValue = 10
        
        // 等待异步操作完成
        waitForExpectations(timeout: 1, handler: nil)
        
        XCTAssertTrue(observed)
        XCTAssertEqual(observedOldValue, 0)
        XCTAssertEqual(observedNewValue, 10)
    }
    
    func testMultipleObservers() {
        // 测试多个观察者
        @XYThreadSafeObservableProperty var value: Int = 0
        
        let expectation1 = self.expectation(description: "Observer 1 called")
        let expectation2 = self.expectation(description: "Observer 2 called")
        var observer1Called = false
        var observer2Called = false
        
        _value.addObserver { _, _ in
            observer1Called = true
            expectation1.fulfill()
        }
        
        _value.addObserver { _, _ in
            observer2Called = true
            expectation2.fulfill()
        }
        
        _value.wrappedValue = 5
        
        // 等待异步操作完成
        waitForExpectations(timeout: 1, handler: nil)
        
        XCTAssertTrue(observer1Called)
        XCTAssertTrue(observer2Called)
    }
    
    func testRemoveObserver() {
        // 测试移除观察者
        @XYThreadSafeObservableProperty var value: Int = 0
        
        let expectation = self.expectation(description: "Observer should not be called")
        expectation.isInverted = true
        
        let id = _value.addObserver { _, _ in
            expectation.fulfill()
        }
        
        _value.removeObserver(with: id)
        _value.wrappedValue = 10
        
        // 等待一小段时间确认观察者未被调用
        waitForExpectations(timeout: 0.1, handler: nil)
    }
    
    func testRemoveAllObservers() {
        // 测试移除所有观察者
        @XYThreadSafeObservableProperty var value: Int = 0
        
        let expectation1 = self.expectation(description: "Observer 1 should not be called")
        let expectation2 = self.expectation(description: "Observer 2 should not be called")
        expectation1.isInverted = true
        expectation2.isInverted = true
        
        _value.addObserver { _, _ in
            expectation1.fulfill()
        }
        
        _value.addObserver { _, _ in
            expectation2.fulfill()
        }
        
        _value.removeAllObservers()
        _value.wrappedValue = 5
        
        // 等待一小段时间确认观察者未被调用
        waitForExpectations(timeout: 0.1, handler: nil)
    }
    
    func testThreadSafetyWithObservers() {
        // 测试带观察者的线程安全
        @XYThreadSafeObservableProperty var counter: Int = 0
        
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "testQueue", attributes: .concurrent)
        
        let expectation = self.expectation(description: "At least one notification")
        expectation.expectedFulfillmentCount = 10 // 期望至少10次通知
        
        var notifications = 0
        let notificationQueue = DispatchQueue(label: "notificationQueue")
        
        _counter.addObserver { _, _ in
            notificationQueue.sync {
                notifications += 1
            }
            expectation.fulfill()
        }
        
        // 启动多个并发线程进行操作
        for i in 0..<10 {
            queue.async(group: group) {
                _counter.wrappedValue = i
            }
        }
        
        // 等待所有操作完成
        group.wait()
        
        // 等待通知处理完成
        waitForExpectations(timeout: 1, handler: nil)
        
        // 验证至少有一次更新
        XCTAssertTrue(notifications > 0)
    }
}
