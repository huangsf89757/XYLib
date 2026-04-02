//
//  XYStateObservableProperty.swift
//  XYCmd
//
//  Created by hsf on 2025/10/2.
//

import Foundation

// MARK: - XYStateObservableProperty
@propertyWrapper
public class XYStateObservableProperty<Value: Equatable> {
    private var value: Value
    private let queue: DispatchQueue
    private var observers: [UUID: ObserverToken<Value>] = [:]
    
    public var wrappedValue: Value {
        get {
            return queue.sync { value }
        }
        set {
            queue.async(flags: .barrier) {
                let oldValue = self.value
                // 只有当值真正变化时才更新和通知
                if oldValue != newValue {
                    self.value = newValue
                    // 过滤掉 context 已经被释放的观察者，同时收集有效的观察者
                    var validObservers: [(UUID, ObserverToken<Value>)] = []
                    for (id, token) in self.observers {
                        if token.context != nil {
                            validObservers.append((id, token))
                        }
                    }
                    
                    // 如果存在无效观察者，则在队列中清理它们
                    if validObservers.count != self.observers.count {
                        self.queue.async(flags: .barrier) {
                            self.observers = Dictionary(uniqueKeysWithValues: validObservers)
                        }
                    }
                    
                    // 通知所有有效观察者
                    for (_, token) in validObservers {
                        token.observer(oldValue, newValue)
                    }
                }
            }
        }
    }
    
    public init(wrappedValue: Value, label: String? = nil) {
        self.value = wrappedValue
        let queueLabel = label ?? "XYStateObservableProperty.\(UUID().uuidString)"
        self.queue = DispatchQueue(label: queueLabel, attributes: .concurrent)
    }
    
    /// 添加观察者，并与指定上下文建立弱引用关系
    /// - Parameters:
    ///   - context: 观察者的所属对象（通常是 self），用于自动管理生命周期
    ///   - observer: 状态变化回调
    /// - Returns: UUID 用于手动移除观察者（可选）
    @discardableResult
    public func addObserver<T: AnyObject>(for context: T, _ observer: @escaping (Value, Value) -> Void) -> UUID {
        let id = UUID()
        let token = ObserverToken<Value>(context: context, observer: observer)
        queue.async(flags: .barrier) {
            self.observers[id] = token
        }
        return id
    }
    
    /// 使用 UUID 移除观察者
    /// - Parameter id: addObserver 返回的 UUID
    public func removeObserver(with id: UUID) {
        queue.async(flags: .barrier) {
            self.observers.removeValue(forKey: id)
        }
    }
    
    /// 移除所有观察者
    public func removeAllObservers() {
        queue.async(flags: .barrier) {
            self.observers.removeAll()
        }
    }
}

// MARK: - ObserverToken
private class ObserverToken<Value: Equatable> {
    weak var context: AnyObject?
    let observer: (Value, Value) -> Void
    
    init(context: AnyObject, observer: @escaping (Value, Value) -> Void) {
        self.context = context
        self.observer = observer
    }
}
