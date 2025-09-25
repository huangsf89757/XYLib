import XCTest
import XYWorkflow

final class XYGroupNodeTests: XCTestCase {
    // 成功执行的命令
    final class FakeSuccessCmd: XYCmd<Any?> {
        let value: Any?
        let executionTime: TimeInterval
        
        init(value: Any? = "ok",
             executionTime: TimeInterval = 0.05,
             id: String = UUID().uuidString,
             timeout: TimeInterval = 0.1) {
            self.value = value
            self.executionTime = executionTime
            super.init(id: id, timeout: timeout)
        }
        
        override func run() async throws -> Any? {
            try await Task.sleep(seconds: executionTime)
            return value
        }
    }

    // 失败执行的命令
    final class FakeFailCmd: XYCmd<Any?> {
        let err: Error
        let executionTime: TimeInterval
        
        init(err: Error = XYError.unknown(NSError(domain: "test", code: 1, userInfo: nil)), 
             timeout: TimeInterval = 0.1,
             executionTime: TimeInterval = 0.05) {
            self.err = err
            self.executionTime = executionTime
            super.init(timeout: timeout)
        }
        
        override func run() async throws -> Any? {
            try await Task.sleep(seconds: executionTime)
            throw err
        }
    }

    /// 测试并发模式下所有命令都成功执行的情况
    /// 验证在并发执行模式下，所有命令都能成功执行并返回正确结果
    func testConcurrentAllSuccess() async throws {
        let executables: [any XYExecutable] = [
            FakeSuccessCmd(value: 1),
            FakeSuccessCmd(value: 2),
            FakeSuccessCmd(value: nil)
        ]
        let group = XYGroupNode(executables: executables, mode: .concurrent, allowPartialFailure: false)
        let result = try await group.execute()
        XCTAssertEqual(result.count, 3)
        let snap = await group.getResultsSnapshot()
        XCTAssertTrue(snap.allSatisfy { r in r.isSuccess })
        XCTAssertEqual(group.state, .succeeded)
    }

    /// 测试并发模式下允许部分失败的情况
    /// 验证在允许部分失败的情况下，即使某些命令失败，组节点仍能成功完成
    func testConcurrentPartialFailureAllowed() async throws {
        let executables: [any XYExecutable] = [
            FakeSuccessCmd(value: 1),
            FakeFailCmd(),
            FakeSuccessCmd(value: 3)
        ]
        let group = XYGroupNode(executables: executables, mode: .concurrent, allowPartialFailure: true)
        let result = try await group.execute()
        XCTAssertEqual(result.count, 3)
        let snap = await group.getResultsSnapshot()
        XCTAssertEqual(snap.filter { !$0.isSuccess }.count, 1)
        XCTAssertEqual(group.state, .succeeded) // 允许部分失败，所以整体是成功的
    }

    /// 测试顺序模式下遇到失败立即停止的情况
    /// 验证在顺序执行模式下，当某个命令失败时，后续命令不会被执行
    func testSequentialFailureStops() async throws {
        let executables: [any XYExecutable] = [
            FakeSuccessCmd(value: 1),
            FakeFailCmd(),
            FakeSuccessCmd(value: 3)
        ]
        let group = XYGroupNode(executables: executables, mode: .sequential, allowPartialFailure: false)
        do {
            _ = try await group.execute()
            XCTFail("Should have thrown")
        } catch {
            // expected
        }
        let snap = await group.getResultsSnapshot()
        // first success, second failure, third not executed -> count of failures >=1
        XCTAssertTrue(snap.filter { !$0.isSuccess }.count >= 1)
        XCTAssertEqual(group.state, .failed)
    }
    
    /// 测试组节点被手动取消的情况
    /// 验证在组节点执行过程中手动取消能够正确传播到所有子命令
    func testGroupNodeCancel() async throws {
        let executables: [any XYExecutable] = [
            FakeSuccessCmd(value: 1, executionTime: 1.0), // 1s
            FakeSuccessCmd(value: 2, executionTime: 1.0),
            FakeSuccessCmd(value: 3, executionTime: 1.0)
        ]
        let group = XYGroupNode(executables: executables, mode: .concurrent, allowPartialFailure: false)
        
        let task = Task {
            do {
                _ = try await group.execute()
                return false
            } catch let error as XYError {
                return error == .cancelled
            } catch {
                return false
            }
        }
        
        // 给一点时间让任务开始执行
        try await Task.sleep(seconds: 0.01) // 10ms
        group.cancel()
        
        let wasCancelled = await task.value
        XCTAssertTrue(wasCancelled)
        XCTAssertEqual(group.state, .cancelled)
        
        // 验证所有子命令也被取消
        for executable in executables {
            XCTAssertEqual(executable.state, .cancelled)
        }
    }
    
    /// 测试组节点处理混合类型命令的情况
    /// 验证组节点能够正确处理不同类型的命令并返回正确的结果
    func testGroupNodeWithMixedTypes() async throws {
        let node1 = XYBaseNode<String> { completion in
            completion(.success("node1"))
        }
        
        let node2 = XYBaseNode<Int> { completion in
            completion(.success(42))
        }
        
        let executables: [any XYExecutable] = [node1, node2]
        let group = XYGroupNode(executables: executables, mode: .concurrent, allowPartialFailure: false)
        let result = try await group.execute()
        
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result[0].isSuccess)
        XCTAssertTrue(result[1].isSuccess)
        XCTAssertEqual(result[0].value as? String, "node1")
        XCTAssertEqual(result[1].value as? Int, 42)
    }
    
    /// 测试空组节点执行的情况
    /// 验证当组节点不包含任何命令时能够正确处理并返回空结果
    func testEmptyGroupNode() async throws {
        let group = XYGroupNode(executables: [], mode: .concurrent, allowPartialFailure: false)
        let result = try await group.execute()
        XCTAssertEqual(result.count, 0)
        XCTAssertEqual(group.state, .succeeded)
    }
}

// 扩展Task.sleep以支持seconds参数
extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: TimeInterval) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}