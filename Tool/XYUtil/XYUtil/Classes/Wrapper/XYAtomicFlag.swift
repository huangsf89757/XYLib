//
//  XYAtomicFlag.swift
//  XYWorkflow
//
//  Created by hsf on 2025/10/2.
//

import Foundation

// MARK: - XYAtomicFlag
public final class XYAtomicFlag {
    private var flag: Bool = false
    private let queue: DispatchQueue
    
    public init(value: Bool = false, label: String? = nil) {
        self.flag = value
        let queueLabel = label ?? "XYAtomicFlag.\(UUID().uuidString)"
        self.queue = DispatchQueue(label: queueLabel, attributes: .concurrent)
    }
    
    public var isSet: Bool {
        return queue.sync { flag }
    }
    
    @discardableResult
    public func set() -> Bool {
        return queue.sync(flags: .barrier) {
            self.flag = true
            return self.flag
        }
    }
    
    @discardableResult
    public func reset() -> Bool {
        return queue.sync(flags: .barrier) {
            self.flag = false
            return self.flag
        }
    }
    
    @discardableResult
    public func toggle() -> Bool {
        return queue.sync(flags: .barrier) {
            self.flag.toggle()
            return self.flag
        }
    }
    
    @discardableResult
    public func compareAndSet(expected: Bool, newValue: Bool) -> Bool {
        return queue.sync(flags: .barrier) {
            if self.flag == expected {
                self.flag = newValue
                return true  // 操作成功
            }
            return false  // 操作失败
        }
    }
}

