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
    /// 同步线程
    private let syncQueue = DispatchQueue(label: "com.xy.util.debounce", attributes: .concurrent)
    
    // MARK: init
    public init(delay: TimeInterval = 1, queue: DispatchQueue = .main) {
        self.delay = delay
        self.queue = queue
    }
    
    // MARK: func
    /// 执行防抖操作（使用初始化时设定的默认延迟）
    /// - Parameter action: 需要执行的任务
    public func work(action: @escaping () -> Void) {
        self.work(delay: delay, action: action)
    }
    
    /// 执行防抖操作（允许临时指定延迟时间）
    /// - Parameters:
    ///   - delay: 延迟时间（秒），会覆盖默认延迟
    ///   - action: 需要执行的任务
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
    
    /// 立即取消当前的防抖任务
    public func cancel() {
        syncQueue.async(flags: .barrier) { [weak self] in
            self?.workItem?.cancel()
            self?.workItem = nil
        }
    }
}
