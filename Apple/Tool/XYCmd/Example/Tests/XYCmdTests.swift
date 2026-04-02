//
//  XYCmdTests.swift
//  XYCmd_Tests
//
//  Created by hsf on 2025/9/18.
//

import XCTest
@testable import XYCmd

// MARK: - Mock Types

enum MockError: Error, Equatable {
    case timeout
    case network
    case invalidInput
}

extension MockError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .timeout:
            return "Timeout"
        case .network:
            return "Network"
        case .invalidInput:
            return "InvalidInput"
        }
    }
}

// MARK: - Testable XYCmd Subclass

class TestCmd: XYCmd<String> {
    var runCallCount = 0
    var shouldSucceedOnAttempt: Int?
    var errorToThrow: Error?
    var delayBeforeRun: TimeInterval = 0

    override func run() async throws -> String {
        runCallCount += 1
        
        if delayBeforeRun > 0 {
            try await Task.sleep(nanoseconds: UInt64(delayBeforeRun * 1_000_000_000))
        }
        
        if let attempt = shouldSucceedOnAttempt, runCallCount >= attempt {
            return "Success on attempt \(runCallCount)"
        }
        
        if let error = errorToThrow {
            throw error
        }
        
        return "Success"
    }
}

// MARK: - XYCmdTests

final class XYCmdTests: XCTestCase {
    
    /// Helper to wait for async result in sync context
    /// - Parameters:
    ///   - asyncCall: Async function to execute
    ///   - timeout: Maximum time to wait
    /// - Returns: Result of the async call
    /// - Throws: Error from the async call if it fails
    func waitFor<T>(_ asyncCall: @escaping () async throws -> T, timeout: TimeInterval = 5) throws -> T {
        let expectation = self.expectation(description: "Async result")
        var result: Result<T, Error>?
        
        Task {
            do {
                let value = try await asyncCall()
                result = .success(value)
            } catch {
                result = .failure(error)
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: timeout)
        switch result! {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
}

// MARK: - Execution Tests

extension XYCmdTests {
    
    /// 测试命令正常执行成功
    func test_execute_success() async throws {
        let cmd = TestCmd()
        let result = try await cmd.execute()
        XCTAssertEqual(result, "Success")
        XCTAssertEqual(cmd.state, .succeeded)
        XCTAssertNotNil(cmd.executeTime)
        XCTAssertNotNil(cmd.finishTime)
        XCTAssertTrue(cmd.finishTime!.timeIntervalSince(cmd.executeTime!) >= 0)
    }
    
    /// 测试命令执行失败（不可重试错误）
    func test_execute_failure_noRetry() async throws {
        let cmd = TestCmd(maxRetries: 3)
        cmd.errorToThrow = MockError.invalidInput // 不可重试错误
        
        do {
            _ = try await cmd.execute()
            XCTFail("Expected command to fail")
        } catch {
            if let xyErr = error as? XYError {
                XCTAssertEqual(xyErr, .other(MockError.invalidInput))
            } else {
                XCTFail("Expected XYError, got: \(error)")
            }
        }
        XCTAssertEqual(cmd.state, .failed)
        XCTAssertEqual(cmd.runCallCount, 1) // 不可重试，只执行一次
    }
    
    /// 测试命令执行超时
    func test_execute_timeout() async throws {
        let cmd = TestCmd(timeout: 0.1)
        cmd.delayBeforeRun = 0.5 // 超过timeout时间
        
        do {
            _ = try await cmd.execute()
            XCTFail("Expected timeout error")
        } catch {
            XCTAssertEqual(error as? XYError, .timeout)
        }
        XCTAssertEqual(cmd.state, .failed)
    }
    
    /// 测试重复执行防护
    func test_execute_while_executing() async throws {
        let cmd = TestCmd()
        cmd.delayBeforeRun = 0.1
        
        let task1 = Task { try await cmd.execute() }
        try await Task.sleep(nanoseconds: 1_000_000) // 确保task1先启动
        let task2 = Task { try await cmd.execute() }
        
        // 第二次执行应被拒绝
        do {
            _ = try await task2.value
            XCTFail("Second execute should be rejected")
        } catch {
            XCTAssertEqual(error as? XYError, .reject)
        }
        
        // 第一次执行应成功
        let result1 = try await task1.value
        XCTAssertEqual(result1, "Success")
        XCTAssertEqual(cmd.state, .succeeded)
    }
}

// MARK: - Retry Tests

extension XYCmdTests {
    
    /// 测试超时后重试成功
    func test_execute_timeout_then_retry_success() async throws {
        let cmd = TestCmd(timeout: 1.0, maxRetries: 1, retryDelay: 0.01)
        cmd.errorToThrow = XYError.timeout // 第一次主动抛出超时错误（可重试）
        cmd.shouldSucceedOnAttempt = 2     // 第二次执行成功
        
        let result = try await cmd.execute()
        
        XCTAssertEqual(result, "Success on attempt 2")
        XCTAssertEqual(cmd.runCallCount, 2) // 执行了两次
        XCTAssertEqual(cmd.state, .succeeded)
    }
    
    /// 测试重试次数耗尽
    func test_execute_retryExhausted() async throws {
        let cmd = TestCmd(timeout: 0.1, maxRetries: 2)
        cmd.delayBeforeRun = 0.2 // 每次都超时
        
        do {
            _ = try await cmd.execute()
            XCTFail("Expected maxRetryExceeded error")
        } catch {
            XCTAssertEqual(error as? XYError, .maxRetryExceeded)
        }
        XCTAssertEqual(cmd.runCallCount, 3) // 初始执行 + 2次重试
        XCTAssertEqual(cmd.curRetries, 2)
    }
    
    /// 测试重试延迟生效
    func test_execute_retryDelay() async throws {
        let retryDelay: TimeInterval = 0.1
        let cmd = TestCmd(maxRetries: 1, retryDelay: retryDelay)
        cmd.errorToThrow = XYError.other(MockError.network) // 可重试错误
        
        let start = Date()
        do {
            _ = try await cmd.execute()
            XCTFail("Expected to fail after retry")
        } catch {
            XCTAssertEqual(error as? XYError, .maxRetryExceeded)
        }
        
        let duration = Date().timeIntervalSince(start)
        XCTAssertEqual(cmd.runCallCount, 2)
        XCTAssertTrue(duration > retryDelay && duration < retryDelay + 0.15)
    }
    
    /// 测试不设置重试次数时不重试
    func test_noRetry_when_maxRetries_nil() async throws {
        let cmd = TestCmd(maxRetries: nil)
        cmd.errorToThrow = XYError.other(MockError.network)
        
        do {
            _ = try await cmd.execute()
            XCTFail("Expected to fail")
        } catch {
            // 预期失败
        }
        XCTAssertEqual(cmd.runCallCount, 1) // 只执行一次
    }
    
    /// 测试重试次数为0时不重试
    func test_noRetry_when_maxRetries_zero() async throws {
        let cmd = TestCmd(maxRetries: 0)
        cmd.errorToThrow = XYError.other(MockError.network)
        
        do {
            _ = try await cmd.execute()
            XCTFail("Expected to fail")
        } catch {
            // 预期失败
        }
        XCTAssertEqual(cmd.runCallCount, 1) // 只执行一次
    }
    
    /// 测试不同类型错误的重试行为
    func test_retryable_errors() async throws {
        let cmd = TestCmd(maxRetries: 1)
        
        // 测试timeout错误（可重试）
        cmd.errorToThrow = XYError.timeout
        do {
            _ = try await cmd.execute()
            XCTFail("Expected to fail after retry")
        } catch {
            XCTAssertEqual(error as? XYError, .maxRetryExceeded)
        }
        XCTAssertEqual(cmd.runCallCount, 2) // 初始 + 1次重试
        cmd.runCallCount = 0
        
        // 测试other错误（可重试）
        cmd.errorToThrow = XYError.other(nil)
        do {
            _ = try await cmd.execute()
            XCTFail("Expected to fail after retry")
        } catch {
            XCTAssertEqual(error as? XYError, .maxRetryExceeded)
        }
        XCTAssertEqual(cmd.runCallCount, 2) // 初始 + 1次重试
        cmd.runCallCount = 0
        
        // 测试cancelled错误（不可重试）
        cmd.errorToThrow = XYError.cancelled
        do {
            _ = try await cmd.execute()
            XCTFail("Expected to fail")
        } catch {
            XCTAssertEqual(error as? XYError, .cancelled)
        }
        XCTAssertEqual(cmd.runCallCount, 1) // 不重试
        cmd.runCallCount = 0
        
        // 测试reject错误（不可重试）
        cmd.errorToThrow = XYError.reject
        do {
            _ = try await cmd.execute()
            XCTFail("Expected to fail")
        } catch {
            XCTAssertEqual(error as? XYError, .reject)
        }
        XCTAssertEqual(cmd.runCallCount, 1) // 不重试
        cmd.runCallCount = 0
        
        // 测试maxRetryExceeded错误（不可重试）
        cmd.errorToThrow = XYError.maxRetryExceeded
        do {
            _ = try await cmd.execute()
            XCTFail("Expected to fail")
        } catch {
            XCTAssertEqual(error as? XYError, .maxRetryExceeded)
        }
        XCTAssertEqual(cmd.runCallCount, 1) // 不重试
        cmd.runCallCount = 0
        
        // 测试notImplemented错误（不可重试）
        cmd.errorToThrow = XYError.notImplemented
        do {
            _ = try await cmd.execute()
            XCTFail("Expected to fail")
        } catch {
            XCTAssertEqual(error as? XYError, .notImplemented)
        }
        XCTAssertEqual(cmd.runCallCount, 1) // 不重试
        cmd.runCallCount = 0
    }
}

// MARK: - Cancellation Tests

extension XYCmdTests {
    
    /// 测试命令执行过程中取消
    func test_cancel_execution() async throws {
        let cmd = TestCmd()
        cmd.delayBeforeRun = 1.0 // 模拟长时间运行
        
        let expectation = self.expectation(description: "Command cancelled")
        
        Task {
            do {
                _ = try await cmd.execute()
                XCTFail("Command should have been cancelled")
            } catch {
                if let xyErr = error as? XYError, xyErr == .cancelled {
                    expectation.fulfill()
                } else {
                    XCTFail("Expected cancellation error, got: \(error)")
                }
            }
        }
        
        // 稍等后取消命令
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        cmd.cancel()
        
        await waitForExpectations(timeout: 3)
        XCTAssertEqual(cmd.state, .cancelled)
    }
    
    /// 测试命令执行前取消
    func test_cancel_before_execution() async throws {
        let cmd = TestCmd()
        
        cmd.cancel()
        
        do {
            _ = try await cmd.execute()
            XCTFail("Command should be cancelled before execution")
        } catch {
            XCTAssertEqual(error as? XYError, .cancelled)
        }
        
        XCTAssertEqual(cmd.state, .cancelled)
    }
    
    /// 测试命令在重试过程中取消
    func test_cancel_during_retry() async throws {
        let cmd = TestCmd(maxRetries: 5, retryDelay: 0.1)
        cmd.errorToThrow = XYError.other(MockError.network) // 可重试错误
        
        let expectation = self.expectation(description: "Command cancelled during retry")
        
        Task {
            do {
                _ = try await cmd.execute()
                XCTFail("Command should have been cancelled during retry")
            } catch {
                if let xyErr = error as? XYError, xyErr == .cancelled {
                    expectation.fulfill()
                } else {
                    XCTFail("Expected cancellation error, got: \(error)")
                }
            }
        }
        
        // 等待一段时间让重试开始
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        cmd.cancel()
        
        await waitForExpectations(timeout: 3)
        XCTAssertEqual(cmd.state, .cancelled)
        XCTAssertTrue(cmd.runCallCount >= 1)
    }
}

// MARK: - State Tests

extension XYCmdTests {
    
    /// 测试命令状态查询方法
    func test_stateQueryMethods() async throws {
        let cmd = TestCmd()
        cmd.delayBeforeRun = 0.1 // 添加延迟以确保有足够时间检测执行中状态
        
        // 验证初始状态
        XCTAssertEqual(cmd.state, .idle)
        XCTAssertFalse(cmd.state.isExecuting)
        XCTAssertFalse(cmd.state.isCompleted)
        
        // 启动执行
        let executionTask = Task {
            try await cmd.execute()
        }
        
        // 等待一小段时间确保进入执行状态
        try await Task.sleep(nanoseconds: 1_000_000) // 1ms
        
        // 验证执行中状态
        XCTAssertEqual(cmd.state, .executing)
        XCTAssertTrue(cmd.state.isExecuting)
        XCTAssertFalse(cmd.state.isCompleted)
        
        // 等待任务完成
        let result = try await executionTask.value
        
        // 验证完成状态
        XCTAssertEqual(cmd.state, .succeeded)
        XCTAssertFalse(cmd.state.isExecuting)
        XCTAssertTrue(cmd.state.isCompleted)
        XCTAssertEqual(result, "Success")
    }
    
    /// 测试命令异步状态变化
    func test_asyncStateChanges() async throws {
        let cmd = TestCmd()
        cmd.delayBeforeRun = 0.1 // 短暂延迟以确保状态变化可观察
        
        // 验证初始状态
        XCTAssertEqual(cmd.state, .idle)
        XCTAssertFalse(cmd.state.isExecuting)
        XCTAssertFalse(cmd.state.isCompleted)
        
        let expectation = self.expectation(description: "Command execution completed")
        var executionResult: Result<String, Error>?
        
        // 异步执行命令
        Task {
            do {
                let result = try await cmd.execute()
                executionResult = .success(result)
            } catch {
                executionResult = .failure(error)
            }
            expectation.fulfill()
        }
        
        // 短暂等待以确保命令进入执行状态
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        
        // 验证执行中状态
        XCTAssertEqual(cmd.state, .executing)
        XCTAssertTrue(cmd.state.isExecuting)
        XCTAssertFalse(cmd.state.isCompleted)
        
        // 等待执行完成
        await waitForExpectations(timeout: 1)
        
        // 验证完成状态
        XCTAssertEqual(cmd.state, .succeeded)
        XCTAssertFalse(cmd.state.isExecuting)
        XCTAssertTrue(cmd.state.isCompleted)
        
        // 验证执行结果
        XCTAssertNotNil(executionResult)
        switch executionResult {
        case .success(let value):
            XCTAssertEqual(value, "Success")
        case .failure(let error):
            XCTFail("Unexpected error: \(error)")
        case .none:
            XCTFail("Execution result should not be nil")
        }
    }
}

// MARK: - Hook Tests

extension XYCmdTests {
    
    /// 测试命令钩子函数（成功情况）
    func test_hookFunctions_success() async throws {
        let cmd = TestCmd()
        
        var willExecuteCalled = false
        var didExecuteCalled = false
        var retryCalled = false
        
        cmd.onWillExecute = {
            willExecuteCalled = true
        }
        
        cmd.onDidExecute = { result in
            didExecuteCalled = true
            switch result {
            case .success(let value):
                XCTAssertEqual(value, "Success")
            case .failure:
                XCTFail("Expected success result")
            }
        }
        
        cmd.onDidRetry = { _, _ in
            retryCalled = true
        }
        
        _ = try await cmd.execute()
        
        XCTAssertTrue(willExecuteCalled)
        XCTAssertTrue(didExecuteCalled)
        XCTAssertFalse(retryCalled) // 没有重试
    }
    
    /// 测试带重试的命令钩子函数
    func test_hookFunctions_withRetry() async throws {
        let cmd = TestCmd(maxRetries: 1, retryDelay: 0.01)
        cmd.errorToThrow = XYError.timeout
        cmd.shouldSucceedOnAttempt = 2
        
        var willExecuteCalled = false
        var didExecuteCalled = false
        var retryCalled = false
        var retryCountAtRetry = 0
        
        cmd.onWillExecute = {
            willExecuteCalled = true
        }
        
        cmd.onDidExecute = { result in
            didExecuteCalled = true
            switch result {
            case .success(let value):
                XCTAssertEqual(value, "Success on attempt 2")
            case .failure:
                XCTFail("Expected success result")
            }
        }
        
        cmd.onDidRetry = { retryCount, error in
            retryCalled = true
            retryCountAtRetry = retryCount
            XCTAssertEqual(error as? XYError, .timeout)
        }
        
        _ = try await cmd.execute()
        
        XCTAssertTrue(willExecuteCalled)
        XCTAssertTrue(didExecuteCalled)
        XCTAssertTrue(retryCalled)
        XCTAssertEqual(retryCountAtRetry, 1)
    }
}
