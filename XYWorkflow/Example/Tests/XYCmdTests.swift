//
//  XYCmdTests.swift
//  YourAppTests
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
                XCTAssertEqual(xyErr, .unknown(MockError.invalidInput))
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
                print("test_cancel_execution", "1")
                _ = try await cmd.execute()
                print("test_cancel_execution", "2")
                XCTFail("Should have been cancelled")
            } catch {
                print("test_cancel_execution", "5")
                if let xyErr = error as? XYError, xyErr == .cancelled {
                    expectation.fulfill()
                } else {
                    XCTFail("Unexpected error: \(error)")
                }
            }
        }
        
        // 稍等后取消
        print("test_cancel_execution", "3")
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        print("test_cancel_execution", "4")
        cmd.cancel()
        
        await waitForExpectations(timeout: 3)
    }
    
    // 8. 重复执行防护
    func test_execute_while_executing() async throws {
        let cmd = TestCmd()
        cmd.delayBeforeRun = 0.1
        
        let task1 = Task { try await cmd.execute() }
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
    
    // 9. executionBlock 模式 - 成功
    func test_executionBlock_success() async throws {
        let cmd = XYCmd<String>(executionBlock: { completion in
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.01) {
                completion(.success("From block"))
            }
        })
        
        let result = try await cmd.execute()
        XCTAssertEqual(result, "From block")
        XCTAssertEqual(cmd.state, .succeeded)
    }
    
    // 10. executionBlock 模式 - 失败
    func test_executionBlock_failure() async throws {
        let cmd = XYCmd<String>(executionBlock: { completion in
            completion(.failure(MockError.network))
        })
        
        do {
            _ = try await cmd.execute()
            XCTFail("Expected failure")
        } catch {
            if let xyErr = error as? XYError {
                XCTAssertEqual(xyErr, .unknown(MockError.network))
            } else {
                XCTFail("Unexpected error type")
            }
        }
        XCTAssertEqual(cmd.state, .failed)
    }
    
    // 11. 无重试：maxRetries = nil
    func test_noRetry_when_maxRetries_nil() async throws {
        let cmd = TestCmd(maxRetries: nil)
        cmd.errorToThrow = MockError.network
        
        do {
            _ = try await cmd.execute()
            XCTFail("Expected to fail")
        } catch {
            // 不重试，直接失败
        }
        XCTAssertEqual(cmd.runCallCount, 1)
    }
    
    // 12. 无重试：maxRetries = 0
    func test_noRetry_when_maxRetries_zero() async throws {
        let cmd = TestCmd(maxRetries: 0)
        cmd.errorToThrow = MockError.network
        
        do {
            _ = try await cmd.execute()
            XCTFail("Expected to fail")
        } catch {
            // 不重试
        }
        XCTAssertEqual(cmd.runCallCount, 1)
    }
}
