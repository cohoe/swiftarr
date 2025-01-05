@testable import swiftarr
import XCTVapor
import Testing

struct ClientControllerTests {
    private func withApp(_ test: (Application) async throws -> ()) async throws {
        let app = try await Application.testable()
        do {
            // try await app.autoMigrate()   
            try await test(app)
        }
        catch {
            // try? await app.autoRevert()
            try await app.asyncShutdown()
            throw error
        }
        try await app.asyncShutdown()
    }
    // var app: Application!

    // override func setUp() async throws {
    //     try await super.setUp()
    //     app = try await Application.testable()
    //     try await app.asyncBoot()
    //     try await app.startup()
    // }

    // override func tearDown() async throws {
    //     try await app.asyncShutdown()
    //     try await super.tearDown()
    // }
	@Test("testClientHealthRoute")
    func testClientHealthRoute() async throws {
        try await withApp { app in
            try await app.test(.GET, "/api/v3/client/health", afterResponse: { res async throws in 
				XCTAssertEqual(res.status, .ok)
			})
        }
    }

	@Test("testNonexistantRoute")
    func testNonexistantRoute() async throws {
		try await withApp { app in
			try await app.test(.GET, "/api/v3/nonexistant", afterResponse: { res async throws in 
				XCTAssertEqual(res.status, .notFound)
			})
		}
    }
}
