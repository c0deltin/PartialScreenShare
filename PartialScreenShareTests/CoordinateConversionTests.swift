import XCTest
@testable import PartialScreenShare

final class CoordinateConversionTests: XCTestCase {
    func testFlipsOriginToTopLeft() {
        // A 200x100 region starting 50pt from the bottom on a 900pt-tall screen.
        let region = CGRect(x: 10, y: 50, width: 200, height: 100)
        let result = CoordinateConversion.sourceRect(fromAppKitRegion: region, screenHeight: 900)

        XCTAssertEqual(result.origin.x, 10)
        XCTAssertEqual(result.origin.y, 750) // 900 - (50 + 100)
        XCTAssertEqual(result.width, 200)
        XCTAssertEqual(result.height, 100)
    }

    func testRegionAtTopOfScreenMapsToOriginZero() {
        let region = CGRect(x: 0, y: 800, width: 300, height: 100)
        let result = CoordinateConversion.sourceRect(fromAppKitRegion: region, screenHeight: 900)

        XCTAssertEqual(result.origin.y, 0)
    }
}
