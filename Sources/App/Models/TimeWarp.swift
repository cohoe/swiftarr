import Foundation
import Vapor
import Fluent


/// A `TimeWarp` is a transition from one apparent time zone to another. Because we are
/// on a boat we frequently cross time zone boundaries. Legend says the captain can also
/// arbitrarily declare what time it is. Hopefully we don't have to worry about the latter.
///
/// We store all known time warps to occur at the time zone of the server (usually UTC) as
/// GMT offsets. The Display Time Zone setting can then be dynamically changed.

final class TimeWarp: Model {
 	static let schema = "timewarp"
 	
	// MARK: Properties
	
	/// The time warp ID, provisioned automatically.
	@ID(key: .id) var id: UUID?
	
	/// Date that the time warp should occur.
	@Field(key: "occur_at") var occurAt: Date

	/// Previous offset. Used to bail if something doesn't match.
	@Field(key: "previous_offset") var previousOffset: Int

	/// New offset.
	@Field(key: "new_offset") var newOffset: Int

	/// Status
	@Field(key: "status") var status: TimeWarpStatus?

	/// Comment
	@Field(key: "comment") var comment: String?
	
	// MARK: Initialization
	
	// Used by Fluent
 	init() { }
 	
	/// Initializes a new TimeWarp.
	///
	/// - Parameters:
	///   - occurAt: Date when the warp occurs.
	///   - previousOffset: The current TimeZone.
	///   - newOffset: The new TimeZone.
	///   - status: Status of the jump. @TODO this is probably not needed.
	///   - comment: An optional comment.
	///
	init(occurAt: Date, previousOffset: Int, newOffset: Int, comment: String? = nil) {
		self.occurAt = occurAt
		self.previousOffset = previousOffset
		self.newOffset = newOffset
		self.status = TimeWarpStatus.scheduled
		self.comment = comment
	}
}

struct CreateTimeWarpSchema: AsyncMigration {
	func prepare(on database: Database) async throws {
		try await database.schema("timewarp")
				.id()
				.field("occur_at", .datetime, .required)
				.field("previous_offset", .int, .required)
				.field("new_offset", .int, .required)
				.field("status", .string)
				.field("comment", .string)
				.create()
	}
	
	func revert(on database: Database) async throws {
		try await database.schema("timewarp").delete()
	}
}

