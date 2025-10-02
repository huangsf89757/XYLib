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
        
        var observed = false
        var observedOldValue: Int?
        var observedNewValue: Int?
        
        _value.addObserver { oldValue, newValue in
            observed = true
            observedOldValue = oldValue
            observedNewValue = newValue
        }
        
        _value.wrappedValue = 10
        
        // 等待异步操作完成
        let expectation = self.expectation(description: "Observer notification")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
        
        XCTAssertTrue(observed)
        XCTAssertEqual(observedOldValue, 0)
        XCTAssertEqual(observedNewValue, 10)
    }
    
    func testMultipleObservers() {
        // 测试多个观察者
        @XYThreadSafeObservableProperty var value: Int = 0
        
        var observer1Called = false
        var observer2Called = false
        
        _value.addObserver { _, _ in
            observer1Called = true
        }
        
        _value.addObserver { _, _ in
            observer2Called = true
        }
        
        _value.wrappedValue = 5
        
        // 等待异步操作完成
        let expectation = self.expectation(description: "Observers notification")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
        
        XCTAssertTrue(observer1Called)
        XCTAssertTrue(observer2Called)
    }
    
    func testRemoveObserver() {
        // 测试移除观察者
        @XYThreadSafeObservableProperty var value: Int = 0
        
        var observerCalled = false
        let id = _value.addObserver { _, _ in
            observerCalled = true
        }
        
        _value.removeObserver(with: id)
        _value.wrappedValue = 10
        
        // 等待异步操作完成
        let expectation = self.expectation(description: "Observer notification")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
        
        XCTAssertFalse(observerCalled)
    }
    
    func testRemoveAllObservers() {
        // 测试移除所有观察者
        @XYThreadSafeObservableProperty var value: Int = 0
        
        var observer1Called = false
        var observer2Called = false
        
        _value.addObserver { _, _ in
            observer1Called = true
        }
        
        _value.addObserver { _, _ in
            observer2Called = true
        }
        
        _value.removeAllObservers()
        _value.wrappedValue = 5
        
        // 等待异步操作完成
        let expectation = self.expectation(description: "Observers notification")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
        
        XCTAssertFalse(observer1Called)
        XCTAssertFalse(observer2Called)
    }
    
    func testThreadSafetyWithObservers() {
        // 测试带观察者的线程安全
        @XYThreadSafeObservableProperty var counter: Int = 0
        
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "testQueue", attributes: .concurrent)
        
        var notifications = 0
        let notificationQueue = DispatchQueue(label: "notificationQueue")
        
        _value.addObserver { _, _ in
            notificationQueue.async {
                notifications += 1
            }
        }
        
        // 启动多个并发线程进行操作
        for i in 0..<100 {
            queue.async(group: group) {
                _counter.wrappedValue = i
            }
        }
        
        // 等待所有操作完成
        group.wait()
        
        // 等待通知处理完成
        let expectation = self.expectation(description: "Notifications processing")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
        
        // 验证至少有一次更新（可能少于100次，因为异步操作）
        XCTAssertTrue(notifications > 0)
    }
}