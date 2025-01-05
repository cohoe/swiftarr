@testable import swiftarr
import XCTVapor

final class SwiftarrBaseTest: XCTestCase {
    var app: Application!

    override func setUp() async throws {
        try await super.setUp()
        app = try await Application.testable()
        try await app.asyncBoot()
        try await app.startup()
    }

    override func tearDown() async throws {
        try await app.asyncShutdown()
        try await super.tearDown()
    }
}
