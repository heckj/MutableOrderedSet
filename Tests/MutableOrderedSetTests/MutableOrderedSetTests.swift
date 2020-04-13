import XCTest
@testable import MutableOrderedSet

final class MutableOrderedSetTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(MutableOrderedSet().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
