import XCTest
import XYWorkflow

final class XYStateAndErrorTests: XCTestCase {
    
    // MARK: - XYState Tests
    
    /// 测试 XYState 枚举的相等性
    /// 验证相同状态的 XYState 实例相等，不同状态的实例不相等
    func testXYStateEquatable() {
        XCTAssertEqual(XYState.idle, XYState.idle)
        XCTAssertEqual(XYState.executing, XYState.executing)
        XCTAssertEqual(XYState.succeeded, XYState.succeeded)
        XCTAssertEqual(XYState.failed, XYState.failed)
        XCTAssertEqual(XYState.cancelled, XYState.cancelled)
        
        XCTAssertNotEqual(XYState.idle, XYState.executing)
        XCTAssertNotEqual(XYState.succeeded, XYState.failed)
    }
    
    /// 测试 XYState 枚举的可哈希性
    /// 验证 XYState 实例可以正确地用作 Set 集合的元素
    func testXYStateHashable() {
        var set: Set<XYState> = []
        set.insert(.idle)
        set.insert(.executing)
        set.insert(.succeeded)
        set.insert(.failed)
        set.insert(.cancelled)
        
        XCTAssertTrue(set.contains(.idle))
        XCTAssertTrue(set.contains(.executing))
        XCTAssertTrue(set.contains(.succeeded))
        XCTAssertTrue(set.contains(.failed))
        XCTAssertTrue(set.contains(.cancelled))
        XCTAssertEqual(set.count, 5)
    }
    
    // MARK: - XYError Tests
    
    /// 测试 XYError 枚举的相等性
    /// 验证相同类型的 XYError 实例相等，不同类型或不同关联值的实例不相等
    func testXYErrorEquatable() {
        XCTAssertEqual(XYError.timeout, XYError.timeout)
        XCTAssertEqual(XYError.cancelled, XYError.cancelled)
        XCTAssertEqual(XYError.executing, XYError.executing)
        XCTAssertEqual(XYError.maxRetryExceeded, XYError.maxRetryExceeded)
        XCTAssertEqual(XYError.notImplemented, XYError.notImplemented)
        
        XCTAssertNotEqual(XYError.timeout, XYError.cancelled)
        XCTAssertNotEqual(XYError.executing, XYError.maxRetryExceeded)
        
        // 测试带有关联值的错误
        let error1 = XYError.other(NSError(domain: "Test", code: 1, userInfo: nil))
        let error2 = XYError.other(NSError(domain: "Test", code: 1, userInfo: nil))
        let error3 = XYError.other(NSError(domain: "Test", code: 2, userInfo: nil))
        let error4 = XYError.unknown(NSError(domain: "Test", code: 1, userInfo: nil))
        
        XCTAssertEqual(error1, error2)
        XCTAssertNotEqual(error1, error3)
        XCTAssertNotEqual(error1, error4) // other 和 unknown 不相等
    }
    
    /// 测试 XYError 枚举的可哈希性
    /// 验证 XYError 实例可以正确地用作 Set 集合的元素
    func testXYErrorHashable() {
        var set: Set<XYError> = []
        set.insert(.timeout)
        set.insert(.cancelled)
        set.insert(.executing)
        set.insert(.maxRetryExceeded)
        set.insert(.notImplemented)
        set.insert(.other(NSError(domain: "Test", code: 1, userInfo: nil)))
        set.insert(.unknown(NSError(domain: "Test", code: 2, userInfo: nil)))
        
        XCTAssertTrue(set.contains(.timeout))
        XCTAssertTrue(set.contains(.cancelled))
        XCTAssertTrue(set.contains(.executing))
        XCTAssertTrue(set.contains(.maxRetryExceeded))
        XCTAssertTrue(set.contains(.notImplemented))
        XCTAssertEqual(set.count, 7)
    }
    
    /// 测试 XYError 的信息描述功能
    /// 验证各种类型的 XYError 能够返回正确的信息描述
    func testXYErrorInfo() {
        XCTAssertEqual(XYError.timeout.info, "timeout")
        XCTAssertEqual(XYError.cancelled.info, "cancelled")
        XCTAssertEqual(XYError.executing.info, "executing")
        XCTAssertEqual(XYError.maxRetryExceeded.info, "maxRetryExceeded")
        XCTAssertEqual(XYError.notImplemented.info, "notImplemented")
        
        let otherError = NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        XCTAssertEqual(XYError.other(otherError).info, "Test error")
        
        let unknownError = NSError(domain: "Unknown", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unknown error"])
        XCTAssertEqual(XYError.unknown(unknownError).info, "Unknown error")
        
        // 测试没有描述的错误
        let noDescriptionError = NSError(domain: "NoDescription", code: 3, userInfo: nil)
        XCTAssertEqual(XYError.other(noDescriptionError).info, "other")
        XCTAssertEqual(XYError.unknown(noDescriptionError).info, "unknown")
    }
}