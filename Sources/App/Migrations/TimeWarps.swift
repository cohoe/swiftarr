import Vapor
import Fluent
import Crypto

struct CreateTimeWarps: AsyncMigration {	
	func prepare(on database: Database) async throws {
		let toStCroix = TimeWarp(
			occurAt: ISO8601DateFormatter().date(from: "2022-11-01T18:00:00-0400")!,
			previousOffset: TimeZone(abbreviation: "EST")!.secondsFromGMT(),
			newOffset: TimeZone(abbreviation: "AST")!.secondsFromGMT(),
			comment: "Make moves son"
		)
		let fromStCroix = TimeWarp(
			occurAt: ISO8601DateFormatter().date(from: "2022-11-01T19:00:00-0400")!,
			previousOffset: TimeZone(abbreviation: "AST")!.secondsFromGMT(),
			newOffset: TimeZone(abbreviation: "EST")!.secondsFromGMT()
		)
		try await toStCroix.save(on: database)
		try await fromStCroix.save(on: database)
	}

	func revert(on database: Database) async throws {
		try await TimeWarp.query(on: database).delete()
	}
}
