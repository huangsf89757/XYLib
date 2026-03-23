//
//  XYDebounce.swift
//  XYUtil
//
//  Created by hsf on 2026/3/20.
//

import Foundation

// MARK: - XYDebounce
/// 防抖
public final class XYDebounce {
    // MARK: var
    /// 延时
    public var delay: TimeInterval
    /// 队列
    public var queue: DispatchQueue
    /// 任务
    public private(set) var workItem: DispatchWorkItem?
    /// 队列
    private let syncQueue = DispatchQueue(label: "com.xy.util.debounce", attributes: .concurrent)
    
    // MARK: init
    public init(delay: TimeInterval = 1, queue: DispatchQueue = .main) {
        self.delay = delay
        self.queue = queue
    }
    
    // MARK: func
    public func work(action: @escaping () -> Void) {
        self.work(delay: delay, action: action)
    }
    
    public func work(delay: TimeInterval, action: @escaping () -> Void) {
        syncQueue.async(flags: .barrier) { [weak self] in
            self?.workItem?.cancel()
            let newWorkItem = DispatchWorkItem { [weak self] in
                action()
                self?.syncQueue.async(flags: .barrier) {
                    self?.workItem = nil
                }
            }
            self?.workItem = newWorkItem
            self?.queue.asyncAfter(deadline: .now() + delay, execute: newWorkItem)
        }
    }
    
    public func cancel() {
        syncQueue.async(flags: .barrier) { [weak self] in
            self?.workItem?.cancel()
            self?.workItem = nil
        }
    }
}
