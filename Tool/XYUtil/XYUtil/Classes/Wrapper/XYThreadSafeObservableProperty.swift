//
//  XYThreadSafeObservableProperty.swift
//  XYWorkflow
//
//  Created by hsf on 2025/10/2.
//

import Foundation

// MARK: - XYThreadSafeObservableProperty
@propertyWrapper
public class XYThreadSafeObservableProperty<Value> {
    private var value: Value
    private let queue: DispatchQueue
    private var observers: [UUID: (Value, Value) -> Void] = [:]
    
    public var wrappedValue: Value {
        get {
            return queue.sync { value }
        }
        set {
            queue.async(flags: .barrier) {
                let oldValue = self.value
                self.value = newValue
                for (_, observer) in self.observers {
                    observer(oldValue, newValue)
                }
            }
        }
    }
    
    public init(wrappedValue: Value, label: String? = nil) {
        self.value = wrappedValue
        let queueLabel = label ?? "XYThreadSafeObservableProperty.\(UUID().uuidString)"
        self.queue = DispatchQueue(label: queueLabel, attributes: .concurrent)
    }
    
    // 添加观察者，返回观察者标识符
    @discardableResult
    public func addObserver(_ observer: @escaping (Value, Value) -> Void) -> UUID {
        let id = UUID()
        queue.async(flags: .barrier) {
            self.observers[id] = observer
        }
        return id
    }
    
    // 移除指定的观察者
    public func removeObserver(with id: UUID) {
        queue.async(flags: .barrier) {
            self.observers.removeValue(forKey: id)
        }
    }
    
    // 移除所有观察者
    public func removeAllObservers() {
        queue.async(flags: .barrier) {
            self.observers.removeAll()
        }
    }
}
