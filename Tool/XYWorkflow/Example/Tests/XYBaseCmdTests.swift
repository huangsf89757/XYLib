//
//  XYBaseCmdTests.swift
//  XYWorkflow_Tests
//
//  Created by Assistant on 2025/10/03.
//

import XCTest
@testable import XYWorkflow

final class XYBaseCmdTests: XCTestCase {
    
    // 1. 测试通过executionBlock创建的命令成功执行
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
    }
    
    // 2. 测试通过executionBlock创建的命令执行失败
    func test_executionBlock_failure() async throws {
        let cmd = XYBaseCmd<String> { completion in
            completion(.failure(MockError.network))
        }
        
        do {
            _ = try await cmd.execute()
            XCTFail("Expected to throw")
        } catch {
            if let xyErr = error as? XYError {
                XCTAssertEqual(xyErr, .other(MockError.network))
            } else {
                XCTFail("Unexpected error type")
            }
        }
        
        XCTAssertEqual(cmd.state, .failed)
    }
    
    // 3. 测试allowsFailureInGroup属性
    func test_allowsFailureInGroup() {
        let cmd = XYBaseCmd<String> { completion in
            completion(.success("Test"))
        }
        
        XCTAssertTrue(cmd.allowsFailureInGroup) // 默认值为true
        
        cmd.allowsFailureInGroup = false
        XCTAssertFalse(cmd.allowsFailureInGroup)
    }
    
    // 4. 测试在executionBlock中处理取消
    func test_executionBlock_cancel() async throws {
        let cmd = XYBaseCmd<String> { completion in
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                completion(.success("Success from block"))
            }
        }
        
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
        try await Task.sleep(nanoseconds: 1_000_000) // 1ms
        cmd.cancel()
        
        await waitForExpectations(timeout: 1)
    }
    
    // 5. 测试没有executionBlock的情况（应该调用super.run）
    func test_withoutExecutionBlock() async throws {
        let cmd = XYBaseCmd<String>()
        
        do {
            _ = try await cmd.execute()
            XCTFail("Expected to throw")
        } catch {
            XCTAssertEqual(error as? XYError, .notImplemented)
        }
        
        XCTAssertEqual(cmd.state, .failed)
    }
    
    // 6. 测试执行前取消executionBlock命令
    func test_executionBlock_cancelBeforeExecute() async throws {
        let cmd = XYBaseCmd<String> { completion in
            completion(.success("Should not be called"))
        }
        
        cmd.cancel()
        
        do {
            _ = try await cmd.execute()
            XCTFail("Expected to throw")
        } catch {
            XCTAssertEqual(error as? XYError, .cancelled)
        }
        
        XCTAssertEqual(cmd.state, .cancelled)
    }
    
    // 7. 测试超时处理
    func test_executionBlock_timeout() async throws {
        let cmd = XYBaseCmd<String>(timeout: 0.1) { completion in
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                completion(.success("Too late"))
            }
        }
        
        do {
            _ = try await cmd.execute()
            XCTFail("Expected timeout")
        } catch {
            XCTAssertEqual(error as? XYError, .timeout)
        }
        
        XCTAssertEqual(cmd.state, .failed)
    }
    
    // 8. 测试重试机制
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
        XCTAssertEqual(callCount, 2)
        XCTAssertEqual(cmd.curRetries, 1)
    }
}
