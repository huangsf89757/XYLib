//
//  XYThrottle.swift
//  XYUtil
//
//  Created by hsf on 2026/3/20.
//

import Foundation

// MARK: - XYThrottle
/// 截流
public final class XYThrottle {
    // MARK: var
    /// 间隔
    public var interval: TimeInterval
    /// 队列
    public var queue: DispatchQueue
    /// 前缘
    public var leading: Bool
    /// 后缘
    public var trailing: Bool
    
    /// 任务
    private var workItem: DispatchWorkItem?
    /// 上次时间
    private var lastFireTime: TimeInterval = 0
    /// 队列
    private let syncQueue = DispatchQueue(label: "com.xy.util.throttle", attributes: .concurrent)
    
    // MARK: init
    public init(interval: TimeInterval = 1,
                queue: DispatchQueue = .main,
                leading: Bool = true,
                trailing: Bool = true) {
        self.interval = interval
        self.queue = queue
        self.leading = leading
        self.trailing = trailing
    }
    
    // MARK: func
    public func work(action: @escaping () -> Void) {
        work(interval: interval, action: action)
    }
    
    public func work(interval: TimeInterval, action: @escaping () -> Void) {
        syncQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            let now = CACurrentMediaTime()
            let timeSinceLastFire = now - self.lastFireTime
            
            let shouldFireImmediately = self.leading && timeSinceLastFire >= interval
            
            if shouldFireImmediately {
                self.lastFireTime = now
                self.workItem?.cancel()
                self.workItem = nil
                
                let item = DispatchWorkItem { action() }
                self.queue.async(execute: item)
            } else if self.trailing {
                self.workItem?.cancel()
                
                let delay = max(0, interval - timeSinceLastFire)
                let item = DispatchWorkItem { [weak self] in
                    action()
                    self?.syncQueue.async(flags: .barrier) {
                        self?.lastFireTime = CACurrentMediaTime()
                        self?.workItem = nil
                    }
                }
                
                self.workItem = item
                self.queue.asyncAfter(deadline: .now() + delay, execute: item)
            }
        }
    }
    
    public func cancel() {
        syncQueue.async(flags: .barrier) { [weak self] in
            self?.workItem?.cancel()
            self?.workItem = nil
        }
    }
}
