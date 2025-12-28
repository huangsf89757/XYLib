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
}

// MARK: - Basic Execution Tests

extension XYCmdTests {
    
    /// Test normal execution success
    func test_execute_success() async throws {
        let cmd = TestCmd()
        let result = try await cmd.execute()
        
        XCTAssertEqual(result, "Success")
        XCTAssertEqual(cmd.state, .succeeded)
        XCTAssertNotNil(cmd.executeTime)
        XCTAssertNotNil(cmd.finishTime)
        XCTAssertTrue(cmd.finishTime!.timeIntervalSince(cmd.executeTime!) >= 0)
    }
    
    /// Test execution failure with error
    func test_execute_failure() async throws {
        let cmd = TestCmd()
        cmd.errorToThrow = XYError.other(MockError.network)
        
        do {
            _ = try await cmd.execute()
            XCTFail("Expected to throw error")
        } catch {
            let normalizedError = cmd.normalizeError(error)
            // 验证错误已被标准化为XYError类型
            XCTAssertNotNil(normalizedError as? XYError)
        }
        
        XCTAssertEqual(cmd.state, .failed)
        XCTAssertEqual(cmd.runCallCount, 1)
    }
}

// MARK: - Retry Tests

extension XYCmdTests {
    
    /// Test retry mechanism with retryable error
    func test_execute_retry_success() async throws {
        let cmd = TestCmd(maxRetries: 2, retryDelay: 0.01)
        cmd.errorToThrow = XYError.timeout
        cmd.shouldSucceedOnAttempt = 2
        
        let result = try await cmd.execute()
        
        XCTAssertEqual(result, "Success on attempt 2")
        XCTAssertEqual(cmd.runCallCount, 2)
        XCTAssertEqual(cmd.curRetries, 1) // 重试次数是执行次数-1
        XCTAssertEqual(cmd.state, .succeeded)
    }
    
    /// Test max retry exceeded
    func test_execute_retryExhausted() async throws {
        let cmd = TestCmd(maxRetries: 2, retryDelay: 0.01)
        cmd.errorToThrow = XYError.timeout
        
        do {
            _ = try await cmd.execute()
            XCTFail("Expected maxRetryExceeded error")
        } catch {
            XCTAssertEqual(error as? XYError, .maxRetryExceeded)
        }
        
        XCTAssertEqual(cmd.runCallCount, 3) // Initial + 2 retries
        XCTAssertEqual(cmd.curRetries, 2)
        XCTAssertEqual(cmd.state, .failed)
    }
    
    /// Test no retry for non-retryable error
    func test_execute_noRetry_for_nonRetryableError() async throws {
        let cmd = TestCmd(maxRetries: 3, retryDelay: 0.01)
        cmd.errorToThrow = XYError.cancelled // Non-retryable
        
        do {
            _ = try await cmd.execute()
            XCTFail("Expected to throw error")
        } catch {
            XCTAssertEqual(error as? XYError, .cancelled)
        }
        
        XCTAssertEqual(cmd.runCallCount, 1) // Should not retry
        XCTAssertEqual(cmd.state, .failed)
    }
    
    /// Test retry delay effectiveness
    func test_execute_retryDelay() async throws {
        let retryDelay: TimeInterval = 0.1
        let cmd = TestCmd(maxRetries: 1, retryDelay: retryDelay)
        cmd.errorToThrow = XYError.other(MockError.network) // Retryable error
        
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
    
    /// Test no retry when maxRetries is nil
    func test_noRetry_when_maxRetries_nil() async throws {
        let cmd = TestCmd(maxRetries: nil)
        cmd.errorToThrow = XYError.other(MockError.network)
        
        do {
            _ = try await cmd.execute()
            XCTFail("Expected to fail")
        } catch {
            // No retry, should fail immediately
        }
        
        XCTAssertEqual(cmd.runCallCount, 1)
    }
    
    /// Test no retry when maxRetries is zero
    func test_noRetry_when_maxRetries_zero() async throws {
        let cmd = TestCmd(maxRetries: 0)
        cmd.errorToThrow = XYError.other(MockError.network)
        
        do {
            _ = try await cmd.execute()
            XCTFail("Expected to fail")
        } catch {
            // No retry, should fail immediately
        }
        
        XCTAssertEqual(cmd.runCallCount, 1)
    }
    
    /// Test retryable error types
    func test_retryable_errors() async throws {
        let cmd = TestCmd(maxRetries: 1)
        
        // Test timeout error (retryable)
        cmd.errorToThrow = XYError.timeout
        do {
            _ = try await cmd.execute()
            XCTFail("Expected to fail")
        } catch {
            XCTAssertEqual(error as? XYError, .maxRetryExceeded)
        }
        XCTAssertEqual(cmd.runCallCount, 2) // Initial + 1 retry
        cmd.runCallCount = 0
        
        // Test other error (retryable)
        cmd.errorToThrow = XYError.other(MockError.network)
        do {
            _ = try await cmd.execute()
            XCTFail("Expected to fail")
        } catch {
            XCTAssertEqual(error as? XYError, .maxRetryExceeded)
        }
        XCTAssertEqual(cmd.runCallCount, 2) // Initial + 1 retry
        cmd.runCallCount = 0
        
        // Test cancelled error (non-retryable)
        cmd.errorToThrow = XYError.cancelled
        do {
            _ = try await cmd.execute()
            XCTFail("Expected to fail")
        } catch {
            XCTAssertEqual(error as? XYError, .cancelled)
        }
        XCTAssertEqual(cmd.runCallCount, 1) // No retry
        cmd.runCallCount = 0
        
        // Test reject error (non-retryable)
        cmd.errorToThrow = XYError.reject
        do {
            _ = try await cmd.execute()
            XCTFail("Expected to fail")
        } catch {
            XCTAssertEqual(error as? XYError, .reject)
        }
        XCTAssertEqual(cmd.runCallCount, 1) // No retry
        cmd.runCallCount = 0
        
        // Test maxRetryExceeded error (non-retryable)
        cmd.errorToThrow = XYError.maxRetryExceeded
        do {
            _ = try await cmd.execute()
            XCTFail("Expected to fail")
        } catch {
            XCTAssertEqual(error as? XYError, .maxRetryExceeded)
        }
        XCTAssertEqual(cmd.runCallCount, 1) // No retry
        cmd.runCallCount = 0
        
        // Test notImplemented error (non-retryable)
        cmd.errorToThrow = XYError.notImplemented
        do {
            _ = try await cmd.execute()
            XCTFail("Expected to fail")
        } catch {
            XCTAssertEqual(error as? XYError, .notImplemented)
        }
        XCTAssertEqual(cmd.runCallCount, 1) // No retry
        cmd.runCallCount = 0
    }
}

// MARK: - Timeout Tests

extension XYCmdTests {
    
    /// Test timeout trigger
    func test_execute_timeout() async throws {
        let cmd = TestCmd(timeout: 0.1)
        cmd.delayBeforeRun = 0.5 // Exceeds timeout
        
        do {
            _ = try await cmd.execute()
            XCTFail("Expected timeout error")
        } catch {
            XCTAssertEqual(error as? XYError, .timeout)
        }
        
        XCTAssertEqual(cmd.state, .failed)
    }
    
    /// Test timeout with retry
    func test_execute_timeout_then_retry_success() async throws {
        let cmd = TestCmd(timeout: 0.1, maxRetries: 1, retryDelay: 0.01)
        cmd.errorToThrow = XYError.timeout // First attempt timeout (retryable)
        cmd.shouldSucceedOnAttempt = 2     // Second attempt success
        
        let start = Date()
        let result = try await cmd.execute()
        let duration = Date().timeIntervalSince(start)
        
        XCTAssertEqual(result, "Success on attempt 2")
        XCTAssertEqual(cmd.runCallCount, 2)
        XCTAssertEqual(cmd.state, .succeeded)
        XCTAssertTrue(duration > 0.01) // Should complete after retry delay
    }
}

// MARK: - Cancellation Tests

extension XYCmdTests {
    
    /// Test cancellation during execution
    func test_cancel_during_execution() async throws {
        let cmd = TestCmd()
        cmd.delayBeforeRun = 0.5 // Simulate long running task
        
        let executionTask = Task {
            try await cmd.execute()
        }
        
        // Wait briefly then cancel
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        cmd.cancel()
        
        do {
            _ = try await executionTask.value
            XCTFail("Should have been cancelled")
        } catch {
            if let xyErr = error as? XYError, xyErr == .cancelled {
                // Expected error
            } else {
                XCTFail("Unexpected error: \(error)")
            }
        }
        
        XCTAssertEqual(cmd.state, .cancelled)
    }
    
    /// Test cancellation before execution
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
    
    /// Test cancellation during retry
    func test_cancel_during_retry() async throws {
        let cmd = TestCmd(maxRetries: 5, retryDelay: 0.1)
        cmd.errorToThrow = XYError.other(MockError.network) // Retryable error
        
        let executionTask = Task {
            try await cmd.execute()
        }
        
        // Wait for retry to start
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        cmd.cancel()
        
        do {
            _ = try await executionTask.value
            XCTFail("Should have been cancelled")
        } catch {
            if let xyErr = error as? XYError, xyErr == .cancelled {
                // Expected error
            } else {
                XCTFail("Unexpected error: \(error)")
            }
        }
        
        XCTAssertTrue(cmd.runCallCount >= 1)
        XCTAssertEqual(cmd.state, .cancelled)
    }
}

// MARK: - State Management Tests

extension XYCmdTests {
    
    /// Test duplicate execution protection
    func test_execute_while_executing() async throws {
        let cmd = TestCmd()
        cmd.delayBeforeRun = 0.1
        
        let task1 = Task { try await cmd.execute() }
        try await Task.sleep(nanoseconds: 1_000_000) // Ensure task1 starts first
        let task2 = Task { try await cmd.execute() }
        
        // Second execute should throw .reject
        do {
            _ = try await task2.value
            XCTFail("Second execute should fail")
        } catch {
            XCTAssertEqual(error as? XYError, .reject)
        }
        
        // First execute should succeed
        let result1 = try await task1.value
        XCTAssertEqual(result1, "Success")
        XCTAssertEqual(cmd.state, .succeeded)
    }
    
    /// Test execute after succeeded
    func test_execute_after_succeeded() async throws {
        let cmd = TestCmd()
        
        // First execution should succeed
        let result1 = try await cmd.execute()
        XCTAssertEqual(result1, "Success")
        XCTAssertEqual(cmd.state, .succeeded)
        
        // Second execution should fail with reject
        do {
            _ = try await cmd.execute()
            XCTFail("Second execute should fail")
        } catch {
            XCTAssertEqual(error as? XYError, .reject)
        }
    }
    
    /// Test execute after failed
    func test_execute_after_failed() async throws {
        let cmd = TestCmd()
        cmd.errorToThrow = XYError.other(MockError.network)
        
        // First execution should fail
        do {
            _ = try await cmd.execute()
            XCTFail("First execute should fail")
        } catch {
            XCTAssertEqual(cmd.state, .failed)
        }
        
        // Second execution should fail with reject
        do {
            _ = try await cmd.execute()
            XCTFail("Second execute should fail")
        } catch {
            XCTAssertEqual(error as? XYError, .reject)
        }
    }
    
    /// Test state transitions during successful execution
    func test_state_transitions_success() async throws {
        let cmd = TestCmd()
        cmd.delayBeforeRun = 0.1 // Add delay to ensure state changes are observable
        
        var observedStates: [XYState] = []
        
        cmd.onStateDidChanged = { state in
            observedStates.append(state)
        }
        
        // Initial state
        XCTAssertEqual(cmd.state, .idle)
        observedStates.append(cmd.state)
        
        // Start execution
        let result = try await cmd.execute()
        
        // Verify all expected states were observed
        XCTAssertEqual(observedStates, [.idle, .executing, .succeeded])
        XCTAssertEqual(result, "Success")
    }
    
    /// Test state transitions during failed execution
    func test_state_transitions_failure() async throws {
        let cmd = TestCmd()
        cmd.errorToThrow = XYError.other(MockError.network)
        
        var observedStates: [XYState] = []
        
        cmd.onStateDidChanged = { state in
            observedStates.append(state)
        }
        
        // Initial state
        XCTAssertEqual(cmd.state, .idle)
        observedStates.append(cmd.state)
        
        // Start execution
        do {
            _ = try await cmd.execute()
            XCTFail("Expected to fail")
        } catch {
            // Expected failure
        }
        
        // Verify all expected states were observed
        XCTAssertEqual(observedStates, [.idle, .executing, .failed])
    }
    
    /// Test state transitions during cancellation
    func test_state_transitions_cancellation() async throws {
        let cmd = TestCmd()
        cmd.delayBeforeRun = 0.5 // Simulate long running task
        
        var observedStates: [XYState] = []
        
        cmd.onStateDidChanged = { state in
            observedStates.append(state)
        }
        
        // Initial state
        XCTAssertEqual(cmd.state, .idle)
        observedStates.append(cmd.state)
        
        // Start execution
        let executionTask = Task {
            try await cmd.execute()
        }
        
        // Wait briefly to ensure executing state is entered
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        // Cancel execution
        cmd.cancel()
        
        do {
            _ = try await executionTask.value
            XCTFail("Should have been cancelled")
        } catch {
            // Expected cancellation error
        }
        
        // Verify all expected states were observed
        XCTAssertEqual(observedStates, [.idle, .executing, .cancelled])
    }
}

// MARK: - Hook Function Tests

extension XYCmdTests {
    
    /// Test hook functions for successful execution
    func test_hookFunctions_success() async throws {
        let cmd = TestCmd()
        
        var willExecuteCalled = false
        var didExecuteCalled = false
        var didExecuteResult: Result<String, Error>?
        var onStateDidChangedCalled = false
        
        cmd.onWillExecute = {
            willExecuteCalled = true
        }
        
        cmd.onDidExecute = { result in
            didExecuteCalled = true
            didExecuteResult = result
        }
        
        cmd.onStateDidChanged = { _ in
            onStateDidChangedCalled = true
        }
        
        let result = try await cmd.execute()
        
        XCTAssertTrue(willExecuteCalled)
        XCTAssertTrue(didExecuteCalled)
        XCTAssertNotNil(didExecuteResult)
        if case .success(let value) = didExecuteResult! {
            XCTAssertEqual(value, result)
        } else {
            XCTFail("Expected success result")
        }
        XCTAssertTrue(onStateDidChangedCalled)
        XCTAssertEqual(result, "Success")
    }
    
    /// Test hook functions for failed execution
    func test_hookFunctions_failure() async throws {
        let cmd = TestCmd()
        cmd.errorToThrow = XYError.other(MockError.network)
        
        var willExecuteCalled = false
        var didExecuteCalled = false
        var didExecuteResult: Result<String, Error>?
        
        cmd.onWillExecute = {
            willExecuteCalled = true
        }
        
        cmd.onDidExecute = { result in
            didExecuteCalled = true
            didExecuteResult = result
        }
        
        do {
            _ = try await cmd.execute()
            XCTFail("Expected to fail")
        } catch {
            // Expected failure
        }
        
        XCTAssertTrue(willExecuteCalled)
        XCTAssertTrue(didExecuteCalled)
        XCTAssertNotNil(didExecuteResult)
        if case .failure = didExecuteResult! {
            // Expected failure result
        } else {
            XCTFail("Expected failure result")
        }
    }
    
    /// Test retry hook function
    func test_hook_retry() async throws {
        let cmd = TestCmd(maxRetries: 1, retryDelay: 0.01)
        cmd.errorToThrow = XYError.timeout
        
        var retryCalled = false
        var retryCount = 0
        var retryError: Error?
        
        cmd.onRetry = { error, count in
            retryCalled = true
            retryCount = count
            retryError = error
        }
        
        do {
            _ = try await cmd.execute()
            XCTFail("Expected to fail after retry")
        } catch {
            XCTAssertEqual(error as? XYError, .maxRetryExceeded)
        }
        
        XCTAssertTrue(retryCalled)
        XCTAssertEqual(retryCount, 1)
        XCTAssertEqual(retryError as? XYError, .timeout)
    }
    
    /// Test onDidCancelExecute hook
    func test_hook_onDidCancelExecute() async throws {
        let cmd = TestCmd()
        cmd.delayBeforeRun = 0.5 // Simulate long running task
        
        var onDidCancelExecuteCalled = false
        
        cmd.onDidCancelExecute = {
            onDidCancelExecuteCalled = true
        }
        
        let executionTask = Task {
            try await cmd.execute()
        }
        
        // Wait briefly then cancel
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        cmd.cancel()
        
        do {
            _ = try await executionTask.value
            XCTFail("Should have been cancelled")
        } catch {
            // Expected cancellation error
        }
        
        XCTAssertTrue(onDidCancelExecuteCalled)
    }
}

// MARK: - Reset Tests

extension XYCmdTests {
    
    /// Test reset functionality after successful execution
    func test_reset_after_success() async throws {
        let cmd = TestCmd()
        
        // Execute command first
        let result = try await cmd.execute()
        XCTAssertEqual(result, "Success")
        XCTAssertEqual(cmd.state, .succeeded)
        XCTAssertNotNil(cmd.executeTime)
        XCTAssertNotNil(cmd.finishTime)
        
        // Reset command
        cmd.reset()
        
        // Verify reset state
        XCTAssertEqual(cmd.state, .idle)
        XCTAssertNil(cmd.executeTime)
        XCTAssertNil(cmd.executeTask)
        XCTAssertEqual(cmd.curRetries, 0)
        
        // Execute again after reset
        let result2 = try await cmd.execute()
        XCTAssertEqual(result2, "Success")
        XCTAssertEqual(cmd.state, .succeeded)
    }
    
    /// Test reset functionality after failed execution
    func test_reset_after_failure() async throws {
        let cmd = TestCmd()
        cmd.errorToThrow = XYError.other(MockError.network)
        
        // Execute command first (should fail)
        do {
            _ = try await cmd.execute()
            XCTFail("Expected to fail")
        } catch {
            XCTAssertEqual(cmd.state, .failed)
        }
        
        // Reset command
        cmd.reset()
        
        // Verify reset state
        XCTAssertEqual(cmd.state, .idle)
        XCTAssertNil(cmd.executeTime)
        XCTAssertNil(cmd.executeTask)
        XCTAssertEqual(cmd.curRetries, 0)
        
        // Fix error and execute again
        cmd.errorToThrow = nil
        let result2 = try await cmd.execute()
        XCTAssertEqual(result2, "Success")
        XCTAssertEqual(cmd.state, .succeeded)
    }
}
