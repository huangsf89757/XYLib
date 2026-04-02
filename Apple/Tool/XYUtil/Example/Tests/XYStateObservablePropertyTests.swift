//
//  XYStateObservablePropertyTests.swift
//  XYUtil_Tests
//
//  Created by hsf on 2025/10/2.
//

import XCTest
@testable import XYUtil

// 遵循Equatable协议的测试枚举
enum TestState: Equatable {
    case idle
    case loading
    case success
    case failed
}

class XYStateObservablePropertyTests: XCTestCase {
    
    func testInitialization() {
        // 测试初始化
        @XYStateObservableProperty var state: TestState = .idle
        XCTAssertEqual(_state.wrappedValue, .idle)
    }
    
    func testObserverNotificationOnValueChange() {
        // 测试值变化时的观察者通知
        @XYStateObservableProperty var state: TestState = .idle
        
        let expectation = self.expectation(description: "Observer called")
        var observed = false
        var observedOldValue: TestState?
        var observedNewValue: TestState?
        
        _state.addObserver(for: self) { oldValue, newValue in
            observed = true
            observedOldValue = oldValue
            observedNewValue = newValue
            expectation.fulfill()
        }
        
        _state.wrappedValue = .loading
        
        // 等待异步操作完成
        waitForExpectations(timeout: 1, handler: nil)
        
        XCTAssertTrue(observed)
        XCTAssertEqual(observedOldValue, .idle)
        XCTAssertEqual(observedNewValue, .loading)
    }
    
    func testNoNotificationOnSameValue() {
        // 测试相同值不会触发通知
        @XYStateObservableProperty var state: TestState = .idle
        
        let expectation = self.expectation(description: "Observer should not be called")
        expectation.isInverted = true
        
        _state.addObserver(for: self) { _, _ in
            expectation.fulfill()
        }
        
        // 设置相同的值
        _state.wrappedValue = .idle
        
        // 等待一小段时间确认观察者未被调用
        waitForExpectations(timeout: 0.1, handler: nil)
    }
    
    func testMultipleObservers() {
        // 测试多个观察者
        @XYStateObservableProperty var state: TestState = .idle
        
        let expectation1 = self.expectation(description: "Observer 1 called")
        let expectation2 = self.expectation(description: "Observer 2 called")
        var observer1Called = false
        var observer2Called = false
        
        _state.addObserver(for: self) { _, _ in
            observer1Called = true
            expectation1.fulfill()
        }
        
        _state.addObserver(for: self) { _, _ in
            observer2Called = true
            expectation2.fulfill()
        }
        
        _state.wrappedValue = .loading
        
        // 等待异步操作完成
        waitForExpectations(timeout: 1, handler: nil)
        
        XCTAssertTrue(observer1Called)
        XCTAssertTrue(observer2Called)
    }
    
    func testAutomaticMemoryManagement() {
        // 测试自动内存管理
        @XYStateObservableProperty var state: TestState = .idle
        
        let expectation = self.expectation(description: "Observer should not be called")
        expectation.isInverted = true
        
        // 创建一个临时对象来添加观察者
        autoreleasepool {
            let tempObject = NSObject()
            _state.addObserver(for: tempObject) { _, _ in
                expectation.fulfill()
            }
        }
        
        // tempObject已被释放，观察者应该被自动清理
        _state.wrappedValue = .loading
        
        // 等待一小段时间确认观察者未被调用
        waitForExpectations(timeout: 0.1, handler: nil)
    }
    
    func testRemoveObserver() {
        // 测试移除观察者
        @XYStateObservableProperty var state: TestState = .idle
        
        let expectation = self.expectation(description: "Observer should not be called")
        expectation.isInverted = true
        
        let id = _state.addObserver(for: self) { _, _ in
            expectation.fulfill()
        }
        
        _state.removeObserver(with: id)
        _state.wrappedValue = .loading
        
        // 等待一小段时间确认观察者未被调用
        waitForExpectations(timeout: 0.1, handler: nil)
    }
    
    func testRemoveAllObservers() {
        // 测试移除所有观察者
        @XYStateObservableProperty var state: TestState = .idle
        
        let expectation1 = self.expectation(description: "Observer 1 should not be called")
        let expectation2 = self.expectation(description: "Observer 2 should not be called")
        expectation1.isInverted = true
        expectation2.isInverted = true
        
        _state.addObserver(for: self) { _, _ in
            expectation1.fulfill()
        }
        
        _state.addObserver(for: self) { _, _ in
            expectation2.fulfill()
        }
        
        _state.removeAllObservers()
        _state.wrappedValue = .loading
        
        // 等待一小段时间确认观察者未被调用
        waitForExpectations(timeout: 0.1, handler: nil)
    }
}