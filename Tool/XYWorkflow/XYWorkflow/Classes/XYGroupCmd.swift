//
//  XYGroupCmd.swift
//  XYWorkflow
//
//  Created by hsf on 2025/9/18.
//

import Foundation
import XYUtil
import XYExtension
import XYLog

// MARK: - XYGroupCmd.ExecutionMode
public extension XYGroupCmd {
    enum ExecutionMode {
        case serial      // 同步串行
        case concurrent  // 异步并发
    }
}

// MARK: - XYGroupCmd.CancelMode
public extension XYGroupCmd {
    enum CancelMode {
        case all          // 取消执行所有子cmd（包括正在执行的）
        case unexecuted   // 仅取消未执行的cmd
    }
}

// MARK: - XYGroupCmd
open class XYGroupCmd: XYCmd<[XYIdentifier: Any]> {
    
    // MARK: execution config
    /// 执行方式，默认：serial
    public let executionMode: ExecutionMode
    /// 子命令发生失败是否中断，默认：true
    public let interruptOnFailure: Bool
    /// 中断group时，如何中断，默认：all
    public let cancelMode: CancelMode
    
    // MARK: private properties
    /// 子命令
    public private(set) var commands: [XYExecutable] = []
    /// 子命令执行结果
    public private(set) var results: ResultType = [:]
    /// 已取消的子命令
    public private(set) var cancelledCommands: Set<XYIdentifier> = []
    
    // MARK: init
    public init(id: XYIdentifier = UUID().uuidString,
                timeout: TimeInterval = 10,
                maxRetries: Int? = nil,
                retryDelay: TimeInterval? = nil,
                executionMode: ExecutionMode = .serial,
                interruptOnFailure: Bool = true,
                cancelMode: CancelMode = .all) {
        self.executionMode = executionMode
        self.interruptOnFailure = interruptOnFailure
        self.cancelMode = cancelMode
        super.init(id: id, timeout: timeout, maxRetries: maxRetries, retryDelay: retryDelay)
        self.logTag = "WorkFlow.GroupCmd"
    }
    
    // MARK: run
    open override func run() async throws -> ResultType {
        return try await self.executeCommands()
    }
    
    // MARK: cancel
    open override func cancel() {
        let tag = [logTag, "cancel"]
        guard state != .cancelled else { return }
        
        executeTask?.cancel()
        switch cancelMode {
        case .all:
            // 中断所有命令（包括正在执行的）
            commands.forEach { $0.cancel() }
        case .unexecuted:
            // 仅中断未执行的命令
            let unexecutedCommands = commands.filter { cmd in
                cmd.state == .idle
            }
            unexecutedCommands.forEach { $0.cancel() }
        }
        
        finishExecution(tag: tag, state: .cancelled, result: nil, error: XYError.cancelled)
    }
}

// MARK: - Execute
extension XYGroupCmd {
    private func executeCommands() async throws -> ResultType {
        switch executionMode {
        case .serial:
            return try await executeSerially()
        case .concurrent:
            return try await executeConcurrently()
        }
    }
    
    private func executeSerially() async throws -> ResultType {
        var results: [XYIdentifier: Any] = [:]
        
        for cmd in commands {
            // 检查取消状态
            if isCancelled() {
                cmd.cancel()
                cancelledCommands.insert(cmd.id)
                continue
            }
            
            do {
                let result = try await cmd.execute()
                results[cmd.id] = result
                
                // 如果中断失败且当前命令失败，根据配置决定是否中断
                if interruptOnFailure && cmd.state == .failed {
                    // 取消后续命令
                    let remainingCommands = commands.dropFirst(commands.firstIndex { $0.id == cmd.id }! + 1)
                    for remainingCmd in remainingCommands {
                        remainingCmd.cancel()
                        cancelledCommands.insert(remainingCmd.id)
                    }
                    break
                }
            } catch {
                results[cmd.id] = error
                if interruptOnFailure {
                    // 取消后续命令
                    let remainingCommands = commands.dropFirst(commands.firstIndex { $0.id == cmd.id }! + 1)
                    for remainingCmd in remainingCommands {
                        remainingCmd.cancel()
                        cancelledCommands.insert(remainingCmd.id)
                    }
                    break
                }
            }
        }
        
        return results
    }
    
    private func executeConcurrently() async throws -> ResultType {
        var results: [XYIdentifier: Any] = [:]
        var tasks: [Task<Void, Never>] = []
        
        // 创建所有任务
        for cmd in commands {
            let task = Task {
                // 检查取消状态
                if isCancelled() {
                    cmd.cancel()
                    cancelledCommands.insert(cmd.id)
                    return
                }
                
                do {
                    let result = try await cmd.execute()
                    results[cmd.id] = result
                } catch {
                    results[cmd.id] = error
                }
            }
            tasks.append(task)
        }
        
        // 等待所有任务完成
        for task in tasks {
            await task.value
        }
        
        return results
    }
}

// MARK: - CRUD Operations
public extension XYGroupCmd {
    // MARK: Add Commands
    func addCommand<T>(_ cmd: XYCmd<T>) {
        guard state == .idle else { return }
        commands.append(cmd)
    }
    
    func addCommands<T>(_ cmds: [XYCmd<T>]) {
        guard state == .idle else { return }
        for cmd in cmds {
            addCommand(cmd)
        }
    }
    
    func insertCommand<T>(_ cmd: XYCmd<T>, at index: Int) {
        guard state == .idle else { return }
        guard index >= 0 && index <= commands.count else { return }
        commands.insert(cmd, at: index)
    }
    
    // MARK: Remove Commands
    @discardableResult
    func removeCommand(withId id: XYIdentifier) -> XYExecutable? {
        guard state == .idle else { return nil }
        if let index = commands.firstIndex(where: { $0.id == id }) {
            return commands.remove(at: index)
        }
        return nil
    }
    
    func removeCommands(withIds ids: [XYIdentifier]) {
        guard state == .idle else { return }
        for id in ids {
            _ = removeCommand(withId: id)
        }
    }
    
    func removeAllCommands() {
        guard state == .idle else { return }
        commands.removeAll()
        results.removeAll()
    }
    
    // MARK: Update Commands
    func updateCommand<T>(withId id: XYIdentifier, newCmd: XYCmd<T>) -> Bool {
        guard state == .idle else { return false }
        if let index = commands.firstIndex(where: { $0.id == id }) {
            commands[index] = newCmd
            return true
        }
        return false
    }
    
    // MARK: Query Commands
    func command(withId id: XYIdentifier) -> XYExecutable? {
        return commands.first { $0.id == id }
    }
    
    func command(at index: Int) -> XYExecutable? {
        guard index >= 0 && index < commands.count else { return nil }
        return commands[index]
    }
    
    var allCommands: [XYExecutable] {
        return commands
    }
    
    var commandCount: Int {
        return commands.count
    }
    
    var executedCommands: [XYExecutable] {
        return commands.filter { $0.state != .idle }
    }
    
    var pendingCommands: [XYExecutable] {
        return commands.filter { $0.state == .idle }
    }
    
    var cancelledCommandIds: Set<XYIdentifier> {
        return cancelledCommands
    }
}

// MARK: - Func
public extension XYGroupCmd {
    /// 获取结果
    func result(forCommandId id: XYIdentifier) -> Any? {
        return results[id]
    }
}
