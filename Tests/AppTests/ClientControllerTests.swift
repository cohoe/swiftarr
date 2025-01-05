@testable import swiftarr
import XCTVapor

final class ClientTests: XCTestCase {
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
    func testClientHealthRoute() async throws {
        let res = try await app.client.get("http://localhost:8081/api/v3/client/health")
        XCTAssertEqual(res.status, .ok)
    }

    // func testNonexistantRoute() async throws {
    //     let res = try await app.client.get("http://localhost:8081/api/v3/nonexistant")
    //     XCTAssertEqual(res.status, .notFound)
    // }
}
