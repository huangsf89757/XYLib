import XCTest
@testable import XYWorkflow

final class XYCmdTests: XCTestCase {
    
    /// 无操作命令，用于测试
    final class NoOpCmd: XYCmd<Int> {
        override func run() async throws -> Int {
            return 42
        }
    }
    
    /// 超时命令，用于测试超时功能
    final class TimeoutCmd: XYCmd<Int> {
        let executionTime: TimeInterval
        
        init(executionTime: TimeInterval = 1.0, timeout: TimeInterval = 10) {
            self.executionTime = executionTime
            super.init(timeout: timeout)
        }
        
        override func run() async throws -> Int {
            try await Task.sleep(seconds: executionTime)
            return 42
        }
    }
    
    /// 测试命令取消功能
    /// 验证命令在被取消时会抛出 cancelled 错误
    func testCancelResumesWithCancelledError() async throws {
        let cmd = TimeoutCmd()
        let t = Task {
            do {
                _ = try await cmd.execute()
                return Optional<XYError>.none
            } catch {
                return error as? XYError
            }
        }
        // wait briefly then cancel
        try await Task.sleep(seconds: 0.01)
        cmd.cancel()
        let res = await t.value
        XCTAssertEqual(res, XYError.cancelled)
    }
    
    /// 测试命令执行过程中的状态转换
    /// 验证命令在执行过程中会经历正确的状态转换：idle -> executing -> succeeded
    func testCmdStateTransitions() async throws {
        let cmd = NoOpCmd()
        XCTAssertEqual(cmd.state, .idle)
        
        let task = Task {
            try await cmd.execute()
        }
        
        // 给一点时间让状态改变
        try await Task.sleep(seconds: 0.001)
        XCTAssertEqual(cmd.state, .executing)
        
        let result = try await task.value
        XCTAssertEqual(result, 42)
        XCTAssertEqual(cmd.state, .succeeded)
    }
    
    /// 测试命令执行超时的情况
    /// 验证命令在执行超时后会被正确处理，状态变为 failed 并抛出 timeout 错误
    func testCmdTimeout() async throws {
        let cmd = TimeoutCmd(executionTime: 1.0, timeout: 0.1) // 1s
        
        do {
            _ = try await cmd.execute()
            XCTFail("Expected timeout")
        } catch let error as XYError {
            XCTAssertEqual(error, .timeout) // 超时应该抛出timeout错误
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        XCTAssertEqual(cmd.state, .failed)
    }
    
    /// 测试命令执行时间记录功能
    /// 验证命令执行时会正确记录执行开始时间
    func testCmdExecuteTime() async throws {
        let cmd = NoOpCmd()
        XCTAssertNil(cmd.executeTime)
        
        _ = try await cmd.execute()
        XCTAssertNotNil(cmd.executeTime)
    }
    
    /// 测试并发执行相同命令会抛出 executing 错误
    /// 验证同一命令不能被并发执行
    func testXYCmdConcurrentExecuteThrowsExecuting() async throws {
        let cmd = TimeoutCmd()
        
        let task1 = Task {
            try await cmd.execute()
        }
        
        // 等待一点时间让第一个任务开始执行
        try await Task.sleep(seconds: 0.001)
        
        do {
            _ = try await cmd.execute()
            XCTFail("Expected executing error")
        } catch let error as XYError {
            XCTAssertEqual(error, .executing)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        task1.cancel()
    }
    
    /// 测试未实现 run 方法会抛出 notImplemented 错误
    /// 验证抽象命令类的正确行为
    func testXYCmdNotImplementedThrows() async throws {
        class UnimplementedCmd: XYCmd<String> { }
        
        let cmd = UnimplementedCmd()
        do {
            _ = try await cmd.execute()
            XCTFail("Expected notImplemented error")
        } catch let error as XYError {
            XCTAssertEqual(error, .notImplemented)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

// 扩展Task.sleep以支持seconds参数
extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: TimeInterval) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}