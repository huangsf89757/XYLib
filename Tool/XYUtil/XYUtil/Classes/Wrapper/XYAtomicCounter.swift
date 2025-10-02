//
//  XYAtomicCounter.swift
//  XYWorkflow
//
//  Created by hsf on 2025/10/2.
//

import Foundation

// MARK: - XYAtomicCounter
public final class XYAtomicCounter {
    private var value: Int = 0
    private let queue: DispatchQueue
    
    public init(value: Int = 0, label: String? = nil) {
        self.value = value
        // 使用并发队列确保操作的原子性
        let queueLabel = label ?? "XYAtomicCounter.\(UUID().uuidString)"
        self.queue = DispatchQueue(label: queueLabel, attributes: .concurrent)
    }
    
    public var current: Int {
        return queue.sync { value }
    }
    
    @discardableResult
    public func increment() -> Int {
        return queue.sync(flags: .barrier) {
            self.value += 1
            return self.value  // 返回新值
        }
    }
    
    @discardableResult
    public func decrement() -> Int {
        return queue.sync(flags: .barrier) {
            self.value -= 1
            return self.value
        }
    }
    
    @discardableResult
    public func add(_ amount: Int) -> Int {
        return queue.sync(flags: .barrier) {
            self.value += amount
            return self.value
        }
    }
    
    @discardableResult
    public func reset(to value: Int = 0) -> Int {
        return queue.sync(flags: .barrier) {
            self.value = value
            return self.value
        }
    }
}
