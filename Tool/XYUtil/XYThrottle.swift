//
//  XYThrottle.swift
//  XYUtil
//
//  Created by hsf on 2026/3/20.
//

import Foundation

// MARK: - XYThrottle
/// 节流
public final class XYThrottle {
    // MARK: var
    /// 间隔
    public var interval: TimeInterval
    /// 队列
    public var queue: DispatchQueue
    /// 任务
    public private(set) var workItem: DispatchWorkItem?
    /// 上次触发时间
    public private(set) var lastFireTime: TimeInterval?
    /// 同步线程
    private let syncQueue = DispatchQueue(label: "com.xy.util.throttle", attributes: .concurrent)
    
    // MARK: init
    public init(interval: TimeInterval = 1, queue: DispatchQueue = .main) {
        self.interval = interval
        self.queue = queue
    }
    
    // MARK: func
    /// 执行节流操作（使用初始化时设定的默认间隔）
    /// - Parameter action: 需要执行的任务
    public func work(action: @escaping () -> Void) {
        self.work(interval: interval, action: action)
    }
    
    /// 执行节流操作（允许临时指定间隔时间）
    /// - Parameters:
    ///   - interval: 间隔时间（秒），会覆盖默认间隔
    ///   - action: 需要执行的任务
    public func work(interval: TimeInterval, action: @escaping () -> Void) {
        syncQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            let now = CACurrentMediaTime()
            if let lastFireTime = self.lastFireTime {
                let timeSinceLastFire = now - lastFireTime
                guard timeSinceLastFire >= interval else {
                    return
                }
            }
            self.lastFireTime = now
            self.workItem?.cancel()
            let newWorkItem = DispatchWorkItem { [weak self] in
                action()
                self?.syncQueue.async(flags: .barrier) {
                    self?.workItem = nil
                }
            }
            self.workItem = newWorkItem
            self.queue.async(execute: newWorkItem)
        }
    }
    
    /// 立即取消当前的节流任务
    public func cancel() {
        syncQueue.async(flags: .barrier) { [weak self] in
            self?.workItem?.cancel()
            self?.workItem = nil
        }
    }
}
