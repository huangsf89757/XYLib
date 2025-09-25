import XCTest
import XYWorkflow

final class XYErrorTests: XCTestCase {
    func testXYErrorEquatable() {
        XCTAssertEqual(XYError.timeout, XYError.timeout)
        XCTAssertNotEqual(XYError.timeout, XYError.cancelled)

        let e1 = XYError.other(NSError(domain: "A", code: 1, userInfo: nil))
        let e2 = XYError.other(NSError(domain: "A", code: 1, userInfo: nil))
        XCTAssertEqual(e1, e2)

        let u1 = XYError.unknown(NSError(domain: "B", code: 2, userInfo: nil))
        let u2 = XYError.unknown(NSError(domain: "B", code: 3, userInfo: nil))
        XCTAssertNotEqual(u1, u2)
    }
}
