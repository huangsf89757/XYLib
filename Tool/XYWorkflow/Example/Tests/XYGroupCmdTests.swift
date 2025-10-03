//
//  XYGroupCmdTests.swift
//  XYWorkflow_Tests
//
//  Created by Assistant on 2025/10/03.
//

import XCTest
@testable import XYWorkflow

// MARK: - XYGroupCmdTests

final class XYGroupCmdTests: XCTestCase {
    
    // 测试串行执行成功
    func test_serialExecution_success() async throws {
        let groupCmd = XYGroupCmd(executionMode: .serial)
        
        let cmd1 = TestCmd()
        let cmd2 = TestCmd()
        let cmd3 = TestCmd()
        
        groupCmd.addCommand(cmd1)
        groupCmd.addCommand(cmd2)
        groupCmd.addCommand(cmd3)
        
        let results = try await groupCmd.execute()
        
        XCTAssertEqual(groupCmd.state, .succeeded)
        XCTAssertEqual(results.count, 3)
        XCTAssertTrue(results.values.allSatisfy { ($0 as? String) == "Success" })
        XCTAssertEqual(cmd1.state, .succeeded)
        XCTAssertEqual(cmd2.state, .succeeded)
        XCTAssertEqual(cmd3.state, .succeeded)
    }
    
    // 测试并发执行成功
    func test_concurrentExecution_success() async throws {
        let groupCmd = XYGroupCmd(executionMode: .concurrent)
        
        let cmd1 = TestCmd()
        let cmd2 = TestCmd()
        let cmd3 = TestCmd()
        
        groupCmd.addCommand(cmd1)
        groupCmd.addCommand(cmd2)
        groupCmd.addCommand(cmd3)
        
        let results = try await groupCmd.execute()
        
        XCTAssertEqual(groupCmd.state, .succeeded)
        XCTAssertEqual(results.count, 3)
        XCTAssertTrue(results.values.allSatisfy { ($0 as? String) == "Success" })
        XCTAssertEqual(cmd1.state, .succeeded)
        XCTAssertEqual(cmd2.state, .succeeded)
        XCTAssertEqual(cmd3.state, .succeeded)
    }
    
    // 测试串行执行中一个命令失败，interruptOnFailure=true
    func test_serialExecution_failure_withInterrupt() async throws {
        let groupCmd = XYGroupCmd(executionMode: .serial, interruptOnFailure: true)
        
        let cmd1 = TestCmd()
        let cmd2 = TestCmd()
        cmd2.errorToThrow = MockError.network
        let cmd3 = TestCmd()
        
        groupCmd.addCommand(cmd1)
        groupCmd.addCommand(cmd2)
        groupCmd.addCommand(cmd3)
        
        let results = try await groupCmd.execute()
        
        XCTAssertEqual(groupCmd.state, .succeeded) // 组命令本身是成功的
        XCTAssertEqual(results.count, 3)
        XCTAssertNotNil(results[cmd1.id] as? String)
        XCTAssertNotNil(results[cmd2.id] as? XYError) // 失败的命令返回包装后的错误
        XCTAssertNotNil(results[cmd3.id] as? XYError) // 被取消的命令返回取消错误
        XCTAssertEqual(cmd1.state, .succeeded)
        XCTAssertEqual(cmd2.state, .failed)
        XCTAssertEqual(cmd3.state, .cancelled) // 因为interruptOnFailure=true，cmd3应该被取消
        
        // 验证cmd2的错误是正确包装的XYError
        if let error = results[cmd2.id] as? XYError {
            XCTAssertEqual(error, XYError.other(MockError.network))
        } else {
            XCTFail("Expected XYError.other for cmd2")
        }
        
        // 验证cmd3的错误是取消错误
        if let error = results[cmd3.id] as? XYError {
            XCTAssertEqual(error, XYError.cancelled)
        } else {
            XCTFail("Expected XYError.cancelled for cmd3")
        }
    }
    
    // 测试串行执行中一个命令失败，interruptOnFailure=false
    func test_serialExecution_failure_withoutInterrupt() async throws {
        let groupCmd = XYGroupCmd(executionMode: .serial, interruptOnFailure: false)
        
        let cmd1 = TestCmd()
        let cmd2 = TestCmd()
        cmd2.errorToThrow = MockError.network
        let cmd3 = TestCmd()
        
        groupCmd.addCommand(cmd1)
        groupCmd.addCommand(cmd2)
        groupCmd.addCommand(cmd3)
        
        let results = try await groupCmd.execute()
        
        XCTAssertEqual(groupCmd.state, .succeeded)
        XCTAssertEqual(results.count, 3)
        XCTAssertNotNil(results[cmd1.id] as? String)
        XCTAssertNotNil(results[cmd2.id] as? XYError)
        XCTAssertNotNil(results[cmd3.id] as? String)
        XCTAssertEqual(cmd1.state, .succeeded)
        XCTAssertEqual(cmd2.state, .failed)
        XCTAssertEqual(cmd3.state, .succeeded)
        
        // 验证cmd2的错误是正确包装的XYError
        if let error = results[cmd2.id] as? XYError {
            XCTAssertEqual(error, XYError.other(MockError.network))
        } else {
            XCTFail("Expected XYError.other for cmd2")
        }
    }
    
    // 测试组命令取消 - CancelMode.all
    func test_groupCancel_all() async throws {
        let groupCmd = XYGroupCmd(executionMode: .concurrent, cancelMode: .all)
        
        let cmd1 = TestCmd()
        cmd1.delayBeforeRun = 0.5
        let cmd2 = TestCmd()
        cmd2.delayBeforeRun = 0.5
        let cmd3 = TestCmd()
        cmd3.delayBeforeRun = 0.5
        
        groupCmd.addCommand(cmd1)
        groupCmd.addCommand(cmd2)
        groupCmd.addCommand(cmd3)
        
        let executionTask = Task {
            try await groupCmd.execute()
        }
        
        // 等待一点时间让任务开始执行
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        // 取消组命令
        groupCmd.cancel()
        
        do {
            _ = try await executionTask.value
            XCTFail("Expected to throw")
        } catch {
            XCTAssertEqual(error as? XYError, .cancelled)
        }
        
        XCTAssertEqual(groupCmd.state, .cancelled)
        // 所有命令都应该被取消
        XCTAssertTrue(cmd1.state == .cancelled || cmd1.state == .succeeded)
        XCTAssertTrue(cmd2.state == .cancelled || cmd2.state == .succeeded)
        XCTAssertTrue(cmd3.state == .cancelled || cmd3.state == .succeeded)
    }
    
    // 测试组命令取消 - CancelMode.unexecuted
    func test_groupCancel_unexecuted() async throws {
        let groupCmd = XYGroupCmd(executionMode: .serial, cancelMode: .unexecuted)
        
        let cmd1 = TestCmd()
        cmd1.delayBeforeRun = 0.1
        let cmd2 = TestCmd()
        cmd2.delayBeforeRun = 0.5
        let cmd3 = TestCmd()
        cmd3.delayBeforeRun = 0.5
        
        groupCmd.addCommand(cmd1)
        groupCmd.addCommand(cmd2)
        groupCmd.addCommand(cmd3)
        
        let executionTask = Task {
            try await groupCmd.execute()
        }
        
        // 等待足够时间让cmd1执行完成
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // 取消组命令
        groupCmd.cancel()
        
        do {
            _ = try await executionTask.value
            XCTFail("Expected to throw")
        } catch {
            XCTAssertEqual(error as? XYError, .cancelled)
        }
        
        XCTAssertEqual(groupCmd.state, .cancelled)
        XCTAssertEqual(cmd1.state, .succeeded) // cmd1已经执行完成，不应该被取消
        XCTAssertTrue(cmd2.state == .cancelled || cmd2.state == .idle) // cmd2应该被取消
        XCTAssertTrue(cmd3.state == .cancelled || cmd3.state == .idle) // cmd3应该被取消
    }
    
    // 测试组命令超时
    func test_groupTimeout() async throws {
        let groupCmd = XYGroupCmd(timeout: 0.1, executionMode: .serial)
        
        let cmd1 = TestCmd()
        cmd1.delayBeforeRun = 0.5 // 超过组命令的超时时间
        
        groupCmd.addCommand(cmd1)
        
        do {
            _ = try await groupCmd.execute()
            XCTFail("Expected timeout")
        } catch {
            XCTAssertEqual(error as? XYError, .timeout)
        }
        
        XCTAssertEqual(groupCmd.state, .failed)
    }
    
    // 测试CRUD操作
    func test_crudOperations() async throws {
        let groupCmd = XYGroupCmd()
        
        let cmd1 = TestCmd()
        let cmd2 = TestCmd()
        let cmd3 = TestCmd()
        
        // 添加命令
        groupCmd.addCommand(cmd1)
        groupCmd.addCommands([cmd2, cmd3])
        
        XCTAssertEqual(groupCmd.commandCount, 3)
        XCTAssertEqual(groupCmd.allCommands.count, 3)
        
        // 插入命令
        let cmd4 = TestCmd()
        groupCmd.insertCommand(cmd4, at: 1)
        
        XCTAssertEqual(groupCmd.commandCount, 4)
        XCTAssertEqual(groupCmd.command(at: 1)?.id, cmd4.id)
        
        // 查询命令
        XCTAssertEqual(groupCmd.command(withId: cmd1.id)?.id, cmd1.id)
        XCTAssertNil(groupCmd.command(withId: "non-existent"))
        
        // 更新命令
        let cmd5 = TestCmd()
        let index = groupCmd.updateCommand(withId: cmd2.id, newCmd: cmd5)
        XCTAssertNotNil(index) // 现在返回索引而不是布尔值
        XCTAssertEqual(index, 2) // cmd2在索引2的位置
        if let index = index {
            XCTAssertEqual(groupCmd.command(at: index)?.id, cmd5.id)
        }
        
        // 删除命令
        XCTAssertNotNil(groupCmd.removeCommand(withId: cmd3.id))
        XCTAssertEqual(groupCmd.commandCount, 3)
        
        // 删除不存在的命令
        XCTAssertNil(groupCmd.removeCommand(withId: "non-existent"))
        
        // 删除多个命令
        groupCmd.removeCommands(withIds: [cmd1.id, cmd4.id])
        XCTAssertEqual(groupCmd.commandCount, 1)
        XCTAssertEqual(groupCmd.command(withId: cmd5.id)?.id, cmd5.id)
        
        // 删除所有命令
        groupCmd.removeAllCommands()
        XCTAssertEqual(groupCmd.commandCount, 0)
    }
    
    // 测试执行后不能再修改命令
    func test_cannotModifyCommandsAfterExecution() async throws {
        let groupCmd = XYGroupCmd()
        let cmd1 = TestCmd()
        
        groupCmd.addCommand(cmd1)
        
        // 执行命令
        _ = try await groupCmd.execute()
        
        // 尝试在执行后添加命令应该无效
        let cmd2 = TestCmd()
        groupCmd.addCommand(cmd2)
        XCTAssertEqual(groupCmd.commandCount, 1) // 应该仍然是1，添加无效
        
        // 尝试在执行后删除命令应该无效
        XCTAssertNil(groupCmd.removeCommand(withId: cmd1.id))
        XCTAssertEqual(groupCmd.commandCount, 1) // 应该仍然是1，删除无效
        
        // 尝试在执行后更新命令应该无效
        let cmd3 = TestCmd()
        let updateResult = groupCmd.updateCommand(withId: cmd1.id, newCmd: cmd3)
        XCTAssertNil(updateResult) // 现在返回nil而不是false
        XCTAssertEqual(groupCmd.command(withId: cmd1.id)?.id, cmd1.id) // 应该仍然是cmd1
    }
    
    // 测试获取命令结果
    func test_getCommandResult() async throws {
        let groupCmd = XYGroupCmd()
        
        let cmd1 = TestCmd()
        let cmd2 = TestCmd()
        cmd2.errorToThrow = MockError.network
        
        groupCmd.addCommand(cmd1)
        groupCmd.addCommand(cmd2)
        
        let results = try await groupCmd.execute()
        
        // 通过results字典获取结果
        XCTAssertNotNil(results[cmd1.id])
        XCTAssertNotNil(results[cmd2.id])
        
        // 通过方法获取结果
        XCTAssertNotNil(groupCmd.result(forCommandId: cmd1.id))
        XCTAssertNotNil(groupCmd.result(forCommandId: cmd2.id))
        XCTAssertNil(groupCmd.result(forCommandId: "non-existent"))
    }
    
    // 测试并发执行中的错误处理
    func test_concurrentExecution_withErrors() async throws {
        let groupCmd = XYGroupCmd(executionMode: .concurrent)
        
        let cmd1 = TestCmd()
        let cmd2 = TestCmd()
        cmd2.errorToThrow = MockError.network
        let cmd3 = TestCmd()
        
        groupCmd.addCommand(cmd1)
        groupCmd.addCommand(cmd2)
        groupCmd.addCommand(cmd3)
        
        let results = try await groupCmd.execute()
        
        XCTAssertEqual(groupCmd.state, .succeeded)
        XCTAssertEqual(results.count, 3)
        XCTAssertNotNil(results[cmd1.id] as? String)
        XCTAssertNotNil(results[cmd2.id] as? XYError)
        XCTAssertNotNil(results[cmd3.id] as? String)
        XCTAssertEqual(cmd1.state, .succeeded)
        XCTAssertEqual(cmd2.state, .failed)
        XCTAssertEqual(cmd3.state, .succeeded)
        
        // 验证cmd2的错误是正确包装的XYError
        if let error = results[cmd2.id] as? XYError {
            XCTAssertEqual(error, XYError.other(MockError.network))
        } else {
            XCTFail("Expected XYError.other for cmd2")
        }
    }
    
    // 测试在执行前取消组命令
    func test_cancelBeforeExecution() async throws {
        let groupCmd = XYGroupCmd(executionMode: .concurrent)
        
        let cmd1 = TestCmd()
        let cmd2 = TestCmd()
        
        groupCmd.addCommand(cmd1)
        groupCmd.addCommand(cmd2)
        
        groupCmd.cancel()
        
        do {
            _ = try await groupCmd.execute()
            XCTFail("Expected to throw")
        } catch {
            XCTAssertEqual(error as? XYError, .cancelled)
        }
        
        XCTAssertEqual(groupCmd.state, .cancelled)
        XCTAssertEqual(cmd1.state, .cancelled)
        XCTAssertEqual(cmd2.state, .cancelled)
    }
    
    // 测试混合XYBaseCmd和TestCmd命令
    func test_mixedCommandTypes() async throws {
        let groupCmd = XYGroupCmd(executionMode: .serial)
        
        let baseCmd = XYBaseCmd<String> { completion in
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.01) {
                completion(.success("From base cmd"))
            }
        }
        
        let testCmd = TestCmd()
        
        groupCmd.addCommand(baseCmd)
        groupCmd.addCommand(testCmd)
        
        let results = try await groupCmd.execute()
        
        XCTAssertEqual(groupCmd.state, .succeeded)
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[baseCmd.id] as? String, "From base cmd")
        XCTAssertEqual(results[testCmd.id] as? String, "Success")
        XCTAssertEqual(baseCmd.state, .succeeded)
        XCTAssertEqual(testCmd.state, .succeeded)
    }
    
    // 测试不同类型结果的命令
    func test_differentResultTypes() async throws {
        let groupCmd = XYGroupCmd(executionMode: .serial)
        
        let stringCmd = XYBaseCmd<String> { completion in
            completion(.success("String result"))
        }
        
        let intCmd = XYBaseCmd<Int> { completion in
            completion(.success(42))
        }
        
        let boolCmd = XYBaseCmd<Bool> { completion in
            completion(.success(true))
        }
        
        groupCmd.addCommand(stringCmd)
        groupCmd.addCommand(intCmd)
        groupCmd.addCommand(boolCmd)
        
        let results = try await groupCmd.execute()
        
        XCTAssertEqual(groupCmd.state, .succeeded)
        XCTAssertEqual(results.count, 3)
        XCTAssertEqual(results[stringCmd.id] as? String, "String result")
        XCTAssertEqual(results[intCmd.id] as? Int, 42)
        XCTAssertEqual(results[boolCmd.id] as? Bool, true)
    }
    
    // 测试组命令中不同类型命令的查询功能
    func test_groupCommandQueryWithDifferentTypes() async throws {
        let groupCmd = XYGroupCmd()
        
        let stringCmd = XYBaseCmd<String> { completion in
            completion(.success("String result"))
        }
        
        let intCmd = XYBaseCmd<Int> { completion in
            completion(.success(42))
        }
        
        let testCmd = TestCmd()
        
        groupCmd.addCommand(stringCmd)
        groupCmd.addCommand(intCmd)
        groupCmd.addCommand(testCmd)
        
        // 测试命令数量
        XCTAssertEqual(groupCmd.commandCount, 3)
        
        // 测试所有命令查询
        let allCommands = groupCmd.allCommands
        XCTAssertEqual(allCommands.count, 3)
        
        // 测试通过ID查询命令
        XCTAssertEqual(groupCmd.command(withId: stringCmd.id)?.id, stringCmd.id)
        XCTAssertEqual(groupCmd.command(withId: intCmd.id)?.id, intCmd.id)
        XCTAssertEqual(groupCmd.command(withId: testCmd.id)?.id, testCmd.id)
        
        // 测试通过索引查询命令
        XCTAssertEqual(groupCmd.command(at: 0)?.id, stringCmd.id)
        XCTAssertEqual(groupCmd.command(at: 1)?.id, intCmd.id)
        XCTAssertEqual(groupCmd.command(at: 2)?.id, testCmd.id)
        
        // 测试待处理命令
        let pendingCommands = groupCmd.pendingCommands
        XCTAssertEqual(pendingCommands.count, 3)
        
        // 执行命令
        _ = try await groupCmd.execute()
        
        // 测试已完成命令
        let executedCommands = groupCmd.executedCommands
        XCTAssertEqual(executedCommands.count, 3)
    }
    
    // 测试取消命令的结果记录
    func test_cancelledCommandResults() async throws {
        let groupCmd = XYGroupCmd(executionMode: .serial, interruptOnFailure: true)
        
        let cmd1 = TestCmd()
        let cmd2 = TestCmd()
        cmd2.errorToThrow = MockError.network // 使第二个命令失败
        let cmd3 = TestCmd()
        
        groupCmd.addCommand(cmd1)
        groupCmd.addCommand(cmd2)
        groupCmd.addCommand(cmd3)
        
        let results = try await groupCmd.execute()
        
        // 验证结果中包含所有命令的记录
        XCTAssertEqual(results.count, 3)
        XCTAssertNotNil(results[cmd1.id] as? String) // 第一个命令成功
        XCTAssertNotNil(results[cmd2.id] as? XYError) // 第二个命令失败
        XCTAssertNotNil(results[cmd3.id] as? XYError) // 第三个命令被取消
        
        // 验证cmd2的错误是正确包装的XYError
        if let error = results[cmd2.id] as? XYError {
            XCTAssertEqual(error, XYError.other(MockError.network))
        } else {
            XCTFail("Expected XYError.other for cmd2")
        }
        
        // 验证第三个命令的结果是cancelled错误
        if let cancelledError = results[cmd3.id] as? XYError {
            XCTAssertEqual(cancelledError, XYError.cancelled)
        } else {
            XCTFail("Expected XYError.cancelled for cmd3")
        }
    }
    
    // 测试组命令取消时的结果记录
    func test_groupCancelResults() async throws {
        let groupCmd = XYGroupCmd(executionMode: .concurrent, cancelMode: .all)
        
        let cmd1 = TestCmd()
        cmd1.delayBeforeRun = 0.5
        let cmd2 = TestCmd()
        cmd2.delayBeforeRun = 0.5
        let cmd3 = TestCmd()
        cmd3.delayBeforeRun = 0.5
        
        groupCmd.addCommand(cmd1)
        groupCmd.addCommand(cmd2)
        groupCmd.addCommand(cmd3)
        
        let executionTask = Task {
            try await groupCmd.execute()
        }
        
        // 等待一点时间让任务开始执行
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        // 取消组命令
        groupCmd.cancel()
        
        do {
            _ = try await executionTask.value
            XCTFail("Expected to throw")
        } catch {
            XCTAssertEqual(error as? XYError, .cancelled)
        }
        
        XCTAssertEqual(groupCmd.state, .cancelled)
        
        // 验证所有命令的结果都被记录为cancelled
        let results = groupCmd.results
        XCTAssertEqual(results.count, 3)
        
        for cmd in [cmd1, cmd2, cmd3] {
            if let resultError = results[cmd.id] as? XYError {
                XCTAssertEqual(resultError, XYError.cancelled)
            } else {
                XCTFail("Expected XYError.cancelled for command \(cmd.id)")
            }
        }
    }
}
