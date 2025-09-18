//
//  XYAnyCmdExecutable.swift
//  Pods
//
//  Created by hsf on 2025/9/16.
//

import Foundation

// MARK: - XYAnyCmdExecutable
public final class XYAnyCmdExecutable: XYCmdExecutable {
    public typealias ResultType = Any?
    
    public let id: String
    public private(set) var state: XYCmdState
    
    private let _execute: () async throws -> Any?
    private let _cancel: () -> Void
    private let _base: any XYCmdExecutable
    
    public init<Base: XYCmdExecutable>(_ base: Base) {
        self.id = base.id
        self.state = base.state
        self._base = base
        
        self._execute = { [weak base] in
            guard let base = base else { throw XYCmdError.cancelled }
            let result = try await base.execute()
            
            // 如果是数组，直接返回；如果是单值，也返回
            // 因为 ResultType == Any?，[Any?] 会被自动装箱
            return result as Any?
        }
        
        self._cancel = { [weak base] in
            base?.cancel()
        }
        
        // 如果你希望状态同步，可以添加观察者（这里简化）
        // 实际项目中建议用 Combine 或 async/await 通知机制
    }
    
    public func execute() async throws -> Any? {
        let result = try await _execute()
        // 同步状态（简化处理，实际应监听 base.state 变化）
        if let base = _base as? any XYCmdExecutable {
            state = base.state
        }
        return result
    }
    
    public func cancel() {
        _cancel()
        state = .cancelled
    }
}

/*
 ====== 示例 ======
 
 let cmd = XYCmd()
 let group = XYCmdGroup(cmds: [...])

 // 包装后可放入统一数组
 let executables: [AnyCmdExecutable] = [
     AnyCmdExecutable(cmd),
     AnyCmdExecutable(group)
 ]

 // 统一执行
 for exe in executables {
     let result = try await exe.execute() // 总是返回 Any?
     
     // 调用者需根据业务知道是单值还是数组
     if let array = result as? [Any?] {
         print("这是组结果，共 \(array.count) 项")
     } else {
         print("这是单命令结果: \(String(describing: result))")
     }
 }
 */
