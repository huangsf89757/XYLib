//
//  XYThreadSafeProperty.swift
//  XYCmd
//
//  Created by hsf on 2025/10/2.
//

import Foundation

// MARK: - XYThreadSafeProperty
@propertyWrapper
public final class XYThreadSafeProperty<Value> {
    private var value: Value
    private let queue: DispatchQueue  // 并发队列，支持读并发写独占
    
    public var wrappedValue: Value {
        get {
            // 读取：同步方式，允许多个线程同时读取
            return queue.sync { value }
        }
        set {
            // 写入：使用屏障，确保写操作的原子性
            queue.async(flags: .barrier) {
                self.value = newValue
            }
        }
    }
    
    public init(wrappedValue: Value, label: String? = nil) {
        self.value = wrappedValue
        // 创建并发队列，读操作可以并发，写操作需要独占
        let queueLabel = label ?? "XYThreadSafeProperty.\(UUID().uuidString)"
        self.queue = DispatchQueue(label: queueLabel, attributes: .concurrent)
    }
    
    // 提供安全的修改方法
    public func withLock<T>(_ action: (inout Value) throws -> T) rethrows -> T {
        return try queue.sync(flags: .barrier) {
            try action(&value)
        }
    }
    
    // 提供安全的读取方法
    public func read<T>(_ action: (Value) throws -> T) rethrows -> T {
        return try queue.sync {
            try action(value)
        }
    }
}

