//
//  XYCmdTests.swift
//  XYWorkflow_Tests
//
//  Created by hsf on 2025/9/18.
//

import XCTest
@testable import XYWorkflow

// MARK: - Mock Types

enum MockError: Error, Equatable {
    case timeout
    case network
    case invalidInput
}

extension MockError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .timeout: return "Timeout"
        case .network: return "Network"
        case .invalidInput: return "InvalidInput"
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
    
    /// Helper to wait for async result in sync context (not used in async tests)
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
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }
}

// MARK: - Async Tests

extension XYCmdTests {
    
    // 1. 正常执行成功
    func test_execute_success() async throws {
        let cmd = TestCmd()
        let result = try await cmd.execute()
        XCTAssertEqual(result, "Success")
        XCTAssertEqual(cmd.state, .succeeded)
        XCTAssertNotNil(cmd.executeTime)
        XCTAssertNotNil(cmd.finishTime)
        XCTAssertTrue(cmd.finishTime!.timeIntervalSince(cmd.executeTime!) >= 0)
    }
    
    // 2. 执行失败（不可重试错误）
    func test_execute_failure_noRetry() async throws {
        let cmd = TestCmd(maxRetries: 3)
        cmd.errorToThrow = MockError.invalidInput // 不可重试
        
        do {
            _ = try await cmd.execute()
            XCTFail("Expected to throw")
        } catch {
            if let xyErr = error as? XYError {
                XCTAssertEqual(xyErr, .other(MockError.invalidInput))
            } else {
                XCTFail("Expected XYError, got: \(error)")
            }
        }
        XCTAssertEqual(cmd.state, .failed)
        XCTAssertEqual(cmd.runCallCount, 1)
    }
    
    // 3. 超时触发
    func test_execute_timeout() async throws {
        let cmd = TestCmd(timeout: 0.1)
        cmd.delayBeforeRun = 0.5 // 超过 timeout
        
        do {
            _ = try await cmd.execute()
            XCTFail("Expected timeout")
        } catch {
            XCTAssertEqual(error as? XYError, .timeout)
        }
        XCTAssertEqual(cmd.state, .failed)
    }
    
    // 4. 超时后重试成功
    func test_execute_timeout_then_retry_success() async throws {
        let cmd = TestCmd(timeout: 1.0, maxRetries: 1, retryDelay: 0.01)
        cmd.errorToThrow = XYError.timeout // 第一次主动抛超时错误（可重试）
        cmd.shouldSucceedOnAttempt = 2     // 第二次成功
        
        let start = Date()
        let result = try await cmd.execute()
        let duration = Date().timeIntervalSince(start)
        
        XCTAssertEqual(result, "Success on attempt 2")
        XCTAssertEqual(cmd.runCallCount, 2)
        XCTAssertEqual(cmd.state, .succeeded)
        XCTAssertTrue(duration < 0.1) // 很快完成
    }
    
    // 5. 重试耗尽
    func test_execute_retryExhausted() async throws {
        let cmd = TestCmd(timeout: 0.1, maxRetries: 2)
        cmd.delayBeforeRun = 0.2 // 每次都超时
        
        do {
            _ = try await cmd.execute()
            XCTFail("Expected maxRetryExceeded")
        } catch {
            XCTAssertEqual(error as? XYError, .maxRetryExceeded)
        }
        XCTAssertEqual(cmd.runCallCount, 3) // 初始 + 2 次重试
        XCTAssertEqual(cmd.curRetries, 2)
    }
    
    // 6. 重试延迟生效
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
    
    // 7. 取消执行
    func test_cancel_execution() async throws {
        let cmd = TestCmd()
        cmd.delayBeforeRun = 1.0 // 模拟长时间运行
        
        let expectation = self.expectation(description: "Command cancelled")
        
        Task {
            do {
                _ = try await cmd.execute()
                XCTFail("Should have been cancelled")
            } catch {
                if let xyErr = error as? XYError, xyErr == .cancelled {
                    expectation.fulfill()
                } else {
                    XCTFail("Unexpected error: \(error)")
                }
            }
        }
        
        // 稍等后取消
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        cmd.cancel()
        
        await waitForExpectations(timeout: 3)
    }
    
    // 7.1 测试在执行前取消
    func test_cancel_before_execution() async throws {
        let cmd = TestCmd()
        
        cmd.cancel()
        
        do {
            _ = try await cmd.execute()
            XCTFail("Should have been cancelled")
        } catch {
            XCTAssertEqual(error as? XYError, .cancelled)
        }
        
        XCTAssertEqual(cmd.state, .cancelled)
    }
    
    // 7.2 测试在重试过程中取消
    func test_cancel_during_retry() async throws {
        let cmd = TestCmd(maxRetries: 5, retryDelay: 0.1)
        cmd.errorToThrow = XYError.other(MockError.network) // 可重试错误
        
        let expectation = self.expectation(description: "Command cancelled during retry")
        
        Task {
            do {
                _ = try await cmd.execute()
                XCTFail("Should have been cancelled")
            } catch {
                if let xyErr = error as? XYError, xyErr == .cancelled {
                    expectation.fulfill()
                } else {
                    XCTFail("Unexpected error: \(error)")
                }
            }
        }
        
        // 等待一段时间让重试开始
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        cmd.cancel()
        
        await waitForExpectations(timeout: 3)
        XCTAssertTrue(cmd.runCallCount >= 1)
    }
    
    // 8. 重复执行防护
    func test_execute_while_executing() async throws {
        let cmd = TestCmd()
        cmd.delayBeforeRun = 0.1
        
        let task1 = Task { try await cmd.execute() }
        try await Task.sleep(nanoseconds: 1_000_000) // 确保task1先启动
        let task2 = Task { try await cmd.execute() }
        
        // 第二次应抛出 .executing
        do {
            _ = try await task2.value
            XCTFail("Second execute should fail")
        } catch {
            XCTAssertEqual(error as? XYError, .executing)
        }
        
        // 第一次应成功
        let result1 = try await task1.value
        XCTAssertEqual(result1, "Success")
        XCTAssertEqual(cmd.state, .succeeded)
    }
    
    // 9. 无重试：maxRetries = nil
    func test_noRetry_when_maxRetries_nil() async throws {
        let cmd = TestCmd(maxRetries: nil)
        cmd.errorToThrow = XYError.other(MockError.network)
        
        do {
            _ = try await cmd.execute()
            XCTFail("Expected to fail")
        } catch {
            // 不重试，直接失败
        }
        XCTAssertEqual(cmd.runCallCount, 1)
    }
    
    // 10. 无重试：maxRetries = 0
    func test_noRetry_when_maxRetries_zero() async throws {
        let cmd = TestCmd(maxRetries: 0)
        cmd.errorToThrow = XYError.other(MockError.network)
        
        do {
            _ = try await cmd.execute()
            XCTFail("Expected to fail")
        } catch {
            // 不重试
        }
        XCTAssertEqual(cmd.runCallCount, 1)
    }
    
    // 11. 测试可重试错误类型
    func test_retryable_errors() async throws {
        let cmd = TestCmd(maxRetries: 1)
        
        // 测试timeout错误（可重试）
        cmd.errorToThrow = XYError.timeout
        do {
            _ = try await cmd.execute()
            XCTFail("Expected to fail")
        } catch {
            XCTAssertEqual(error as? XYError, .maxRetryExceeded)
        }
        XCTAssertEqual(cmd.runCallCount, 2) // 初始 + 1次重试
        cmd.runCallCount = 0
        
        // 测试other错误（可重试）
        cmd.errorToThrow = XYError.other(nil)
        do {
            _ = try await cmd.execute()
            XCTFail("Expected to fail")
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
        
        // 测试executing错误（不可重试）
        cmd.errorToThrow = XYError.executing
        do {
            _ = try await cmd.execute()
            XCTFail("Expected to fail")
        } catch {
            XCTAssertEqual(error as? XYError, .executing)
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
    
    // 12. 测试状态查询方法
    func test_stateQueryMethods() async throws {
        let cmd = TestCmd()
        cmd.delayBeforeRun = 0.1 // 添加延迟以确保有足够时间检测执行中状态
        
        // 初始状态
        XCTAssertEqual(cmd.state, .idle)
        XCTAssertFalse(cmd.isExecuting)
        XCTAssertFalse(cmd.isCompleted)
        
        // 启动执行
        let executionTask = Task {
            try await cmd.execute()
        }
        
        // 等待一小段时间确保进入执行状态
        try await Task.sleep(nanoseconds: 1_000_000) // 1ms
        
        // 验证执行中状态
        XCTAssertEqual(cmd.state, .executing)
        XCTAssertTrue(cmd.isExecuting)
        XCTAssertFalse(cmd.isCompleted)
        
        // 等待任务完成
        let result = try await executionTask.value
        
        // 验证完成状态
        XCTAssertEqual(cmd.state, .succeeded)
        XCTAssertFalse(cmd.isExecuting)
        XCTAssertTrue(cmd.isCompleted)
        XCTAssertEqual(result, "Success")
    }
    
    // 13. 测试钩子函数
    func test_hookFunctions() async throws {
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
                XCTFail("Expected success")
            }
        }
        
        cmd.onRetry = { error, retryCount in
            retryCalled = true
        }
        
        _ = try await cmd.execute()
        
        XCTAssertTrue(willExecuteCalled)
        XCTAssertTrue(didExecuteCalled)
        XCTAssertFalse(retryCalled) // 没有重试
    }
    
    // 14. 测试带重试的钩子函数
    func test_hookFunctionsWithRetry() async throws {
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
                XCTFail("Expected success")
            }
        }
        
        cmd.onRetry = { error, retryCount in
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
    
    // 15. 测试异步状态变化
    func test_asyncStateChanges() async throws {
        let cmd = TestCmd()
        cmd.delayBeforeRun = 0.1 // 短暂延迟以确保状态变化可观察
        
        // 初始状态
        XCTAssertEqual(cmd.state, .idle)
        XCTAssertFalse(cmd.isExecuting)
        XCTAssertFalse(cmd.isCompleted)
        
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
        XCTAssertTrue(cmd.isExecuting)
        XCTAssertFalse(cmd.isCompleted)
        
        // 等待执行完成
        await waitForExpectations(timeout: 1)
        
        // 验证完成状态
        XCTAssertEqual(cmd.state, .succeeded)
        XCTAssertFalse(cmd.isExecuting)
        XCTAssertTrue(cmd.isCompleted)
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
