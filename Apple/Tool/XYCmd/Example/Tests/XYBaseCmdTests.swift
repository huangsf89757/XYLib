//
//  XYBaseCmdTests.swift
//  XYCmd_Tests
//
//  Created by Assistant on 2025/10/03.
//

import XCTest
@testable import XYCmd

// MARK: - Mock Types

// MARK: - XYBaseCmdTests

final class XYBaseCmdTests: XCTestCase {
    
}

// MARK: - Basic Execution Tests

extension XYBaseCmdTests {
    
    /// 测试通过executionBlock创建的命令成功执行
    func test_executionBlock_success() async throws {
        let expectation = self.expectation(description: "Execution block called")
        
        let cmd = XYBaseCmd<String> { completion in
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.01) {
                expectation.fulfill()
                completion(.success("Success from block"))
            }
        }
        
        let result = try await cmd.execute()
        await waitForExpectations(timeout: 1)
        
        XCTAssertEqual(result, "Success from block")
        XCTAssertEqual(cmd.state, .succeeded)
        XCTAssertNotNil(cmd.executeTime)
        XCTAssertNotNil(cmd.finishTime)
        XCTAssertTrue(cmd.finishTime!.timeIntervalSince(cmd.executeTime!) >= 0)
    }
    
    /// 测试没有设置executionBlock时的行为
    func test_withoutExecutionBlock() async throws {
        let cmd = XYBaseCmd<String>()
        
        do {
            _ = try await cmd.execute()
            XCTFail("Expected command to throw NotImplemented error")
        } catch {
            XCTAssertEqual(error as? XYError, .notImplemented)
        }
        
        XCTAssertEqual(cmd.state, .failed)
    }
    
    /// 测试不同类型结果的执行块
    func test_differentResultTypes() async throws {
        // 测试String类型
        let stringCmd = XYBaseCmd<String> { completion in
            completion(.success("String result"))
        }
        let stringResult = try await stringCmd.execute()
        XCTAssertEqual(stringResult, "String result")
        XCTAssertEqual(stringCmd.state, .succeeded)
        
        // 测试Int类型
        let intCmd = XYBaseCmd<Int> { completion in
            completion(.success(42))
        }
        let intResult = try await intCmd.execute()
        XCTAssertEqual(intResult, 42)
        XCTAssertEqual(intCmd.state, .succeeded)
        
        // 测试Bool类型
        let boolCmd = XYBaseCmd<Bool> { completion in
            completion(.success(true))
        }
        let boolResult = try await boolCmd.execute()
        XCTAssertEqual(boolResult, true)
        XCTAssertEqual(boolCmd.state, .succeeded)
        
        // 测试Optional类型
        let optionalCmd = XYBaseCmd<String?> { completion in
            completion(.success(nil))
        }
        let optionalResult = try await optionalCmd.execute()
        XCTAssertNil(optionalResult)
        XCTAssertEqual(optionalCmd.state, .succeeded)
    }
}

// MARK: - Failure Tests

extension XYBaseCmdTests {
    
    /// 测试通过executionBlock创建的命令执行失败
    func test_executionBlock_failure() async throws {
        let cmd = XYBaseCmd<String> { completion in
            completion(.failure(MockError.network))
        }
        
        do {
            _ = try await cmd.execute()
            XCTFail("Expected command to fail")
        } catch {
            if let xyErr = error as? XYError {
                XCTAssertEqual(xyErr, .other(MockError.network))
            } else {
                XCTFail("Unexpected error type: \(error)")
            }
        }
        
        XCTAssertEqual(cmd.state, .failed)
    }
    
    /// 测试不同类型的错误处理
    func test_differentErrorTypes() async throws {
        // MockError类型
        let mockErrorCmd = XYBaseCmd<String> { completion in
            completion(.failure(MockError.invalidInput))
        }
        
        do {
            _ = try await mockErrorCmd.execute()
            XCTFail("Expected command to fail with MockError")
        } catch {
            if let xyErr = error as? XYError {
                XCTAssertEqual(xyErr, .other(MockError.invalidInput))
            } else {
                XCTFail("Unexpected error type for MockError")
            }
        }
        
        // XYError类型
        let xyErrorCmd = XYBaseCmd<String> { completion in
            completion(.failure(XYError.timeout))
        }
        
        do {
            _ = try await xyErrorCmd.execute()
            XCTFail("Expected command to fail with XYError")
        } catch {
            XCTAssertEqual(error as? XYError, .timeout)
        }
        
        // NSError类型
        let nsErrorCmd = XYBaseCmd<String> { completion in
            let nsError = NSError(domain: "com.test.error", code: 42, userInfo: nil)
            completion(.failure(nsError))
        }
        
        do {
            _ = try await nsErrorCmd.execute()
            XCTFail("Expected command to fail with NSError")
        } catch {
            if let xyErr = error as? XYError {
                XCTAssertEqual(xyErr, .other(NSError(domain: "com.test.error", code: 42, userInfo: nil)))
            } else {
                XCTFail("Unexpected error type for NSError")
            }
        }
    }
}

// MARK: - Cancellation Tests

extension XYBaseCmdTests {
    
    /// 测试在executionBlock执行过程中取消命令
    func test_cancel_execution() async throws {
        let cmd = XYBaseCmd<String> { completion in
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                completion(.success("Success from block"))
            }
        }
        
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
        
        await waitForExpectations(timeout: 1)
        XCTAssertEqual(cmd.state, .cancelled)
    }
    
    /// 测试在执行前取消executionBlock命令
    func test_cancel_beforeExecution() async throws {
        let cmd = XYBaseCmd<String> { completion in
            completion(.success("Should not be called"))
        }
        
        cmd.cancel()
        
        do {
            _ = try await cmd.execute()
            XCTFail("Command should be cancelled before execution")
        } catch {
            XCTAssertEqual(error as? XYError, .cancelled)
        }
        
        XCTAssertEqual(cmd.state, .cancelled)
    }
    
    /// 测试取消后状态的正确性
    func test_cancel_stateValidation() async throws {
        let cmd = XYBaseCmd<String> { completion in
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.05) {
                completion(.success("Result"))
            }
        }
        
        XCTAssertEqual(cmd.state, .idle)
        
        let executionTask = Task { try await cmd.execute() }
        
        // 等待命令开始执行
        try await Task.sleep(nanoseconds: 5_000_000) // 5ms
        XCTAssertEqual(cmd.state, .executing)
        
        // 取消命令
        cmd.cancel()
        
        do {
            _ = try await executionTask.value
            XCTFail("Expected command to be cancelled")
        } catch {
            XCTAssertEqual(error as? XYError, .cancelled)
        }
        
        XCTAssertEqual(cmd.state, .cancelled)
    }
}

// MARK: - Timeout Tests

extension XYBaseCmdTests {
    
    /// 测试executionBlock命令的超时处理
    func test_executionBlock_timeout() async throws {
        let cmd = XYBaseCmd<String>(timeout: 0.1) { completion in
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                completion(.success("Too late"))
            }
        }
        
        do {
            _ = try await cmd.execute()
            XCTFail("Expected command to timeout")
        } catch {
            XCTAssertEqual(error as? XYError, .timeout)
        }
        
        XCTAssertEqual(cmd.state, .failed)
    }
    
    /// 测试超时后不会执行完成回调
    func test_timeout_noCompletionAfterTimeout() async throws {
        let completionExpectation = self.expectation(description: "Completion should not be called after timeout")
        completionExpectation.isInverted = true // 不希望这个期望被满足
        
        let cmd = XYBaseCmd<String>(timeout: 0.05) { completion in
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                completionExpectation.fulfill()
                completion(.success("Too late"))
            }
        }
        
        do {
            _ = try await cmd.execute()
            XCTFail("Expected command to timeout")
        } catch {
            XCTAssertEqual(error as? XYError, .timeout)
        }
        
        await waitForExpectations(timeout: 0.15)
        XCTAssertEqual(cmd.state, .failed)
    }
}

// MARK: - Retry Tests

extension XYBaseCmdTests {
    
    /// 测试executionBlock命令的重试机制
    func test_executionBlock_retry() async throws {
        var callCount = 0
        let cmd = XYBaseCmd<String>(maxRetries: 1, retryDelay: 0.01) { completion in
            callCount += 1
            if callCount == 1 {
                completion(.failure(XYError.timeout))
            } else {
                completion(.success("Success on retry"))
            }
        }
        
        let result = try await cmd.execute()
        
        XCTAssertEqual(result, "Success on retry")
        XCTAssertEqual(cmd.state, .succeeded)
        XCTAssertEqual(callCount, 2) // 执行了两次（初始+1次重试）
        XCTAssertEqual(cmd.curRetries, 1)
    }
    
    /// 测试重试次数耗尽
    func test_retry_maxAttemptsExceeded() async throws {
        var callCount = 0
        let maxRetries = 2
        let cmd = XYBaseCmd<String>(maxRetries: maxRetries, retryDelay: 0.01) { completion in
            callCount += 1
            completion(.failure(XYError.other(MockError.network)))
        }
        
        do {
            _ = try await cmd.execute()
            XCTFail("Expected command to fail after max retries")
        } catch {
            XCTAssertEqual(error as? XYError, .maxRetryExceeded)
        }
        
        XCTAssertEqual(cmd.state, .failed)
        XCTAssertEqual(callCount, maxRetries + 1) // 初始执行 + maxRetries次重试
        XCTAssertEqual(cmd.curRetries, maxRetries)
    }
    
    /// 测试不可重试错误的重试行为
    func test_retry_nonRetryableError() async throws {
        var callCount = 0
        let cmd = XYBaseCmd<String>(maxRetries: 3, retryDelay: 0.01) { completion in
            callCount += 1
            completion(.failure(MockError.invalidInput))
        }
        
        do {
            _ = try await cmd.execute()
            XCTFail("Expected command to fail with non-retryable error")
        } catch {
            if let xyErr = error as? XYError {
                XCTAssertEqual(xyErr, .other(MockError.invalidInput))
            } else {
                XCTFail("Unexpected error type")
            }
        }
        
        XCTAssertEqual(cmd.state, .failed)
        XCTAssertEqual(callCount, 1) // 不可重试错误，只执行一次
        XCTAssertEqual(cmd.curRetries, 0)
    }
    
    /// 测试重试延迟的正确性
    func test_retry_delay() async throws {
        let retryDelay: TimeInterval = 0.1
        var callCount = 0
        var callTimes: [Date] = []
        
        let cmd = XYBaseCmd<String>(maxRetries: 1, retryDelay: retryDelay) { completion in
            callTimes.append(Date())
            callCount += 1
            completion(.failure(XYError.timeout))
        }
        
        let startTime = Date()
        
        do {
            _ = try await cmd.execute()
            XCTFail("Expected command to fail after retry")
        } catch {
            XCTAssertEqual(error as? XYError, .maxRetryExceeded)
        }
        
        let totalDuration = Date().timeIntervalSince(startTime)
        let retryDuration = callTimes[1].timeIntervalSince(callTimes[0])
        
        XCTAssertEqual(callCount, 2)
        XCTAssertTrue(retryDuration >= retryDelay)
        XCTAssertTrue(totalDuration >= retryDelay)
    }
}

// MARK: - Property Tests

extension XYBaseCmdTests {
    
    /// 测试allowsFailureInGroup属性的默认值和修改
    func test_allowsFailureInGroup() {
        let cmd = XYBaseCmd<String> { completion in
            completion(.success("Test"))
        }
        
        XCTAssertTrue(cmd.allowsFailureInGroup) // 默认值为true
        
        cmd.allowsFailureInGroup = false
        XCTAssertFalse(cmd.allowsFailureInGroup)
        
        cmd.allowsFailureInGroup = true
        XCTAssertTrue(cmd.allowsFailureInGroup)
    }
    
    /// 测试logTag属性的正确性
    func test_logTag() {
        let cmd = XYBaseCmd<String> { completion in
            completion(.success("Test"))
        }
        
        // 默认logTag
        XCTAssertEqual(cmd.logTag, ["XYBaseCmd"])
        
        // 修改logTag
        cmd.logTag = ["CustomTag"]
        XCTAssertEqual(cmd.logTag, ["CustomTag"])
        
        // 修改为多元素logTag
        cmd.logTag = ["Tag1", "Tag2"]
        XCTAssertEqual(cmd.logTag, ["Tag1", "Tag2"])
    }
}

// MARK: - State Tests

extension XYBaseCmdTests {
    
    /// 测试命令执行过程中的状态变化
    func test_stateTransitions() async throws {
        let cmd = XYBaseCmd<String> { completion in
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.01) {
                completion(.success("Result"))
            }
        }
        
        // 初始状态
        XCTAssertEqual(cmd.state, .idle)
        XCTAssertFalse(cmd.state.isExecuting)
        XCTAssertFalse(cmd.state.isCompleted)
        
        // 执行命令
        let executionTask = Task { try await cmd.execute() }
        
        // 等待命令开始执行
        try await Task.sleep(nanoseconds: 2_000_000) // 2ms
        XCTAssertEqual(cmd.state, .executing)
        XCTAssertTrue(cmd.state.isExecuting)
        XCTAssertFalse(cmd.state.isCompleted)
        
        // 等待命令完成
        let result = try await executionTask.value
        XCTAssertEqual(result, "Result")
        
        // 完成状态
        XCTAssertEqual(cmd.state, .succeeded)
        XCTAssertFalse(cmd.state.isExecuting)
        XCTAssertTrue(cmd.state.isCompleted)
    }
    
    /// 测试失败时的状态变化
    func test_stateTransitions_failure() async throws {
        let cmd = XYBaseCmd<String> { completion in
            completion(.failure(MockError.network))
        }
        
        XCTAssertEqual(cmd.state, .idle)
        
        do {
            _ = try await cmd.execute()
            XCTFail("Expected command to fail")
        } catch {
            // 预期失败
        }
        
        XCTAssertEqual(cmd.state, .failed)
        XCTAssertFalse(cmd.state.isExecuting)
        XCTAssertTrue(cmd.state.isCompleted)
    }
}

// MARK: - Hook Tests

extension XYBaseCmdTests {
    
    /// 测试命令成功执行时的钩子函数
    func test_hookFunctions_success() async throws {
        var willExecuteCalled = false
        var didExecuteCalled = false
        var executionResult: Result<String, Error>?
        
        let cmd = XYBaseCmd<String> { completion in
            completion(.success("Success"))
        }
        
        cmd.onWillExecute = { willExecuteCalled = true }
        cmd.onDidExecute = { result in 
            didExecuteCalled = true
            executionResult = result
        }
        
        let result = try await cmd.execute()
        
        XCTAssertEqual(result, "Success")
        XCTAssertTrue(willExecuteCalled)
        XCTAssertTrue(didExecuteCalled)
        XCTAssertNotNil(executionResult)
        if case .success(let value) = executionResult! {
            XCTAssertEqual(value, "Success")
        } else {
            XCTFail("Expected success result")
        }
    }
    
    /// 测试命令失败时的钩子函数
    func test_hookFunctions_failure() async throws {
        var willExecuteCalled = false
        var didExecuteCalled = false
        var executionResult: Result<String, Error>?
        
        let cmd = XYBaseCmd<String> { completion in
            completion(.failure(MockError.network))
        }
        
        cmd.onWillExecute = { willExecuteCalled = true }
        cmd.onDidExecute = { result in 
            didExecuteCalled = true
            executionResult = result
        }
        
        do {
            _ = try await cmd.execute()
            XCTFail("Expected command to fail")
        } catch {
            // 预期失败
        }
        
        XCTAssertTrue(willExecuteCalled)
        XCTAssertTrue(didExecuteCalled)
        XCTAssertNotNil(executionResult)
        if case .failure(let error) = executionResult! {
            if let xyErr = error as? XYError {
                XCTAssertEqual(xyErr, .other(MockError.network))
            } else {
                XCTFail("Expected XYError, got: \(error)")
            }
        } else {
            XCTFail("Expected failure result")
        }
    }
    
    /// 测试带重试的钩子函数
    func test_hookFunctions_withRetry() async throws {
        var willExecuteCalled = 0
        var didExecuteCalled = 0
        var retryCalled = 0
        var lastRetryError: Error?
        
        let cmd = XYBaseCmd<String>(maxRetries: 1, retryDelay: 0.01) { completion in
            completion(.failure(XYError.timeout))
        }
        
        cmd.onWillExecute = { willExecuteCalled += 1 }
        cmd.onDidExecute = { _ in didExecuteCalled += 1 }
        cmd.onDidRetry = { _, error in
            retryCalled += 1
            lastRetryError = error
        }
        
        do {
            _ = try await cmd.execute()
            XCTFail("Expected command to fail after retry")
        } catch {
            XCTAssertEqual(error as? XYError, .maxRetryExceeded)
        }
        
        XCTAssertEqual(willExecuteCalled, 2) // 初始执行 + 1次重试
        XCTAssertEqual(didExecuteCalled, 1) // 只在最终完成时调用一次
        XCTAssertEqual(retryCalled, 1) // 重试了一次
        XCTAssertEqual(lastRetryError as? XYError, .timeout)
    }
}

// MARK: - Complex Scenarios Tests

extension XYBaseCmdTests {
    
    /// 测试超时与重试的组合场景
    func test_timeout_withRetry() async throws {
        var callCount = 0
        let cmd = XYBaseCmd<String>(timeout: 0.05, maxRetries: 1, retryDelay: 0.01) { completion in
            callCount += 1
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                completion(.success("Result"))
            }
        }
        
        do {
            _ = try await cmd.execute()
            XCTFail("Expected command to fail after timeout and retry")
        } catch {
            XCTAssertEqual(error as? XYError, .maxRetryExceeded)
        }
        
        XCTAssertEqual(cmd.state, .failed)
        XCTAssertEqual(callCount, 2) // 初始执行 + 1次重试
    }
    
    /// 测试取消与重试的组合场景
    func test_cancel_withRetry() async throws {
        var callCount = 0
        let cmd = XYBaseCmd<String>(maxRetries: 3, retryDelay: 0.05) { completion in
            callCount += 1
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.02) {
                completion(.failure(XYError.timeout))
            }
        }
        
        let executionTask = Task { try await cmd.execute() }
        
        // 等待一段时间让重试开始
        try await Task.sleep(nanoseconds: 70_000_000) // 70ms，足够第一次重试开始
        
        // 取消命令
        cmd.cancel()
        
        do {
            _ = try await executionTask.value
            XCTFail("Expected command to be cancelled")
        } catch {
            XCTAssertEqual(error as? XYError, .cancelled)
        }
        
        XCTAssertEqual(cmd.state, .cancelled)
        XCTAssertTrue(callCount >= 2) // 至少执行了初始和一次重试
    }
    
    /// 测试快速连续调用execute()
    func test_multipleExecuteCalls() async throws {
        let cmd = XYBaseCmd<String> { completion in
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.01) {
                completion(.success("Result"))
            }
        }
        
        // 同时执行两个任务
        let task1 = Task { try await cmd.execute() }
        let task2 = Task { try await cmd.execute() }
        
        let result1 = try await task1.value
        XCTAssertEqual(result1, "Result")
        
        do {
            _ = try await task2.value
            XCTFail("Second execute should fail with reject error")
        } catch {
            XCTAssertEqual(error as? XYError, .reject)
        }
        
        XCTAssertEqual(cmd.state, .succeeded)
    }
    
    /// 测试命令执行时间记录
    func test_executionTiming() async throws {
        let cmd = XYBaseCmd<String> { completion in
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.02) {
                completion(.success("Result"))
            }
        }
        
        XCTAssertNil(cmd.executeTime)
        XCTAssertNil(cmd.finishTime)
        
        let startTime = Date()
        _ = try await cmd.execute()
        let endTime = Date()
        
        XCTAssertNotNil(cmd.executeTime)
        XCTAssertNotNil(cmd.finishTime)
        XCTAssertTrue(cmd.executeTime!.timeIntervalSince(startTime) >= 0)
        XCTAssertTrue(endTime.timeIntervalSince(cmd.finishTime!) >= 0)
        XCTAssertTrue(cmd.finishTime!.timeIntervalSince(cmd.executeTime!) >= 0.02) // 至少延迟了0.02秒
    }
}
