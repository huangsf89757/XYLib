import XCTest
import XYWorkflow

final class XYStateTests: XCTestCase {
    func testXYStateEquatableAndHashable() {
        XCTAssertEqual(XYState.idle, XYState.idle)
        XCTAssertNotEqual(XYState.idle, XYState.executing)
        var set: Set<XYState> = []
        set.insert(.idle)
        set.insert(.executing)
        XCTAssertTrue(set.contains(.idle))
        XCTAssertTrue(set.contains(.executing))
    }
}
