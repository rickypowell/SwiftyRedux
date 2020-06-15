import XCTest
@testable import SwiftyRedux

final class SwiftyReduxTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(SwiftyRedux().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
