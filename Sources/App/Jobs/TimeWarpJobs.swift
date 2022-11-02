import Vapor
import Queues

struct CleanupJob: AsyncScheduledJob {
    // Add extra services here via dependency injection, if you need them.

    func run(context: QueueContext) async throws {
        // Do some work here, perhaps queue up another job.
        print("Hello!")

        var urlComponents = Settings.shared.apiUrlComponents
		guard let apiPathURL: URL = URL(string: urlComponents.path), let endpointComponents: URLComponents = URLComponents(string: "/client/health") else {
		 	throw Abort(.internalServerError, reason: "Unable to decode API URL components.")
		}
		urlComponents.path = apiPathURL.appendingPathComponent(endpointComponents.path).absoluteString
        guard let apiURLString = urlComponents.string else {
		 	throw Abort(.internalServerError, reason: "Unable to build URL to API endpoint.")
    	}

        let test = try await context.application.client.send(.GET, to: URI(string: apiURLString))
        print(test.content)
        // Settings.shared.displayTimeZoneAbbr = "AST"
        // Can't manipulate shared settings becuase we're in a special process/thread
        // AND it needs to write/read the settings.
    }
}