import Vapor
import FluentPostgreSQL

// model uses Int as primary key
extension ForumPost: PostgreSQLModel {}

// model can be passed as HTTP body data
extension ForumPost: Content {}

// model can be used as endpoint parameter
extension ForumPost: Parameter {}

// MARK: - Custom Migration

extension ForumPost: Migration {
    /// Required by `Migration` protocol. Creates the table, with foreign key  constraint
    /// to `Forum`.
    ///
    /// - Parameter connection: The connection to the database, usually the Request.
    /// - Returns: Void.
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) {
            (builder) in
            try addProperties(to: builder)
            // foreign key constraint to Forum
            builder.reference(from: \.forumID, to: \Forum.id)
        }
    }
}

// MARK: - Timestamping Conformance

extension ForumPost {
    /// Required key for `\.createdAt` functionality.
    static var createdAtKey: TimestampKey? { return \.createdAt }
    /// Required key for `\.updatedAt` functionality.
    static var updatedAtKey: TimestampKey? { return \.updatedAt }
    /// Required key for `\.deletedAt` soft delete functionality.
    static var deletedAtKey: TimestampKey? { return \.deletedAt }
}

// MARK: - Parent

extension ForumPost {
    /// The parent `Forum` of the post.
    var forum: Parent<ForumPost, Forum> {
        return parent(\.forumID)
    }
}

// MARK: - Children

extension ForumPost {
    /// The child `ForumEdit` accountability records of the profile.
    var edits: Children<ForumPost, ForumEdit> {
        return children(\.postID)
    }
}

// MARK: - Functions

extension ForumPost {
    /// Converts an `ForumPost` model to a version omitting data that is of no interest to a user.
    func convertToData() throws -> PostData {
        return try PostData(
            postID: self.requireID(),
            createdAt: self.createdAt ?? Date(),
            authorID: self.authorID,
            text: self.text,
            image: self.image
        )
    }
}

extension Future where T: ForumPost {
    /// Converts a `Future<ForumPost>` to a `Future<PostData>`. This extension provides
    /// the convenience of simply using `post.convertToData()` and allowing the compiler to
    /// choose the appropriate version for the context.
    func convertToData() -> Future<PostData> {
        return self.map {
            (forumPost) in
            return try forumPost.convertToData()
        }
    }
}

