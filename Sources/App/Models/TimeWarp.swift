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

	/// Offset.
	@Field(key: "offset") var offset: Int

	/// Status
	@Field(key: "status") var status: TimeWarpStatus?

	/// Comment
	@Field(key: "comment") var comment: String?

	/// Timestamp of the model's creation, set automatically.
	@Timestamp(key: "created_at", on: .create) var createdAt: Date?
	
	/// Timestamp of the model's last update, set automatically.
	@Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

	/// The parent `User` who created the timewarp.
	@Parent(key: "creator") var creator: User
	
	// MARK: Initialization
	
	// Used by Fluent
 	init() { }
 	
	/// Initializes a new TimeWarp.
	///
	/// - Parameters:
	///   - occurAt: Date when the warp occurs.
	///   - offset: Seconds from GMT.
	///   - status: Status of the jump. @TODO this is probably not needed.
	///   - comment: An optional comment.
	///
	// init(occurAt: Date, previousOffset: Int, offset: Int, comment: String? = nil, creator: UUID) {
	// 	self.occurAt = occurAt
	// 	self.offset = offset
	// 	self.status = TimeWarpStatus.scheduled
	// 	self.comment = comment
	// 	self.creator = creator
	// }
	init(creatorID: UUID, occurAt: Date, offset: Int, comment: String? = nil) {
		self.$creator.id = creatorID
		self.occurAt = occurAt
		self.offset = offset
		self.comment = comment
	}
}

struct CreateTimeWarpSchema: AsyncMigration {
	func prepare(on database: Database) async throws {
		try await database.schema("timewarp")
				.id()
				.field("occur_at", .datetime, .required)
				.field("offset", .int, .required)
				.field("status", .string)
				.field("comment", .string)
				.field("created_at", .datetime)
				.field("updated_at", .datetime)
				.field("creator", .uuid, .required, .references("user", "id"))
				.create()
	}
	
	func revert(on database: Database) async throws {
		try await database.schema("timewarp").delete()
	}
}

