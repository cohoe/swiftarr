import Vapor
import Logging
import NIOCore
import NIOPosix

@main
enum Entrypoint {
	// This fn copied from the Vapor template generated by Vapor 4.100.0
    static func main() async throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)
        
        let app = try await Application.make(env)

        // This attempts to install NIO as the Swift Concurrency global executor.
        // You should not call any async functions before this point.
//		let executorTakeoverSuccess = NIOSingletons.unsafeTryInstallSingletonPosixEventLoopGroupAsConcurrencyGlobalExecutor()
//		app.logger.debug("Running with \(executorTakeoverSuccess ? "SwiftNIO" : "standard") Swift Concurrency default executor")
        
        do {
			try await SwiftarrConfigurator(app).configure()
            try SwiftarrConfigurator.configurePrometheus(app)
        } catch {
            app.logger.report(error: error)
            try? await app.asyncShutdown()
            throw error
        }
        try await execute(app: app)
        try await app.asyncShutdown()
    }

	/// Copied the Application.execute() method here, modified it to call our own copy of startup(). See below.
	/// Original header comment from Vapor sources:
	/// 
    /// > Starts the ``Application`` asynchronous using the ``startup()`` method, then waits for any running tasks
    /// > to complete. If your application is started without arguments, the default argument is used.
    ///
    /// > Under normal circumstances, ``execute()`` runs until a shutdown is triggered, then wait for the web server to
    /// > (manually) shut down before returning.
    static func execute(app: Application) async throws {
        do {
            try await startup(app: app)
            try await app.running?.onStop.get()
        } catch {
            app.logger.report(error: error)
            throw error
        }
    }
    
	/// Copied Vapor's Application.startup() method here, modified it to call postBootConfigure() after boot but before commands are run.
	/// This lets us do things like load saved settings values from Redis after Redis is up and running but before the server starts.
	/// We also run a bunch of sanity checks on the Postgres and Redis dbs, because the sanity checks provide much better errors than Fluent/RedisKit.
	/// Original header comment from Vapor sources:
	/// 
    /// > When called, this will asynchronously execute the startup command provided through an argument. If no startup
    /// > command is provided, the default is used. Under normal circumstances, this will start running Vapor's webserver.
    ///
    /// > If you start Vapor through this method, you'll need to prevent your Swift Executable from closing yourself.
    /// > If you want to run your ``Application`` indefinitely, or until your code shuts the application down,
    /// > use ``execute()`` instead.
    static func startup(app: Application) async throws {
        try await app.asyncBoot()

		try await SwiftarrConfigurator(app).postBootConfigure()

        let combinedCommands = AsyncCommands(
            commands: app.asyncCommands.commands.merging(app.commands.commands) { $1 },
            defaultCommand: app.asyncCommands.defaultCommand ?? app.commands.defaultCommand,
            enableAutocomplete: app.asyncCommands.enableAutocomplete || app.commands.enableAutocomplete
        ).group()

        var context = CommandContext(console: app.console, input: app.environment.commandInput)
        context.application = app
        try await app.console.run(combinedCommands, with: context)
    }
}
