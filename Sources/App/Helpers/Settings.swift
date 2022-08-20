import Vapor
import Redis

/// A (hopefully) thread-safe singleton that provides modifiable global settings.

final class Settings : Encodable {
	
	/// Wraps settings properties, making them thread-safe. All access to the internalValue 
	@propertyWrapper class SettingsValue<T>: Encodable where T: Encodable {
		fileprivate var internalValue: T
		var wrappedValue: T {
			get { return Settings.settingsQueue.sync { internalValue } }
			set { Settings.settingsQueue.async { self.internalValue = newValue } }
		}
		
		init(wrappedValue: T) {
			internalValue = wrappedValue
		}
		
		func encode(to encoder: Encoder) throws {
			var container = encoder.singleValueContainer();
			try container.encode(wrappedValue)
		}
	}

	/// Wraps settings properties, making them thread-safe. Contains methods for loading/storing values from a Redis hash.
	/// Use this for settings that should be database-backed.
	@propertyWrapper class StoredSettingsValue<T>: SettingsValue<T>, StoredSetting where T : Encodable & RESPValueConvertible {
		var projectedValue: StoredSettingsValue<T> { self }
		var redisField: String
		override var wrappedValue: T {
			get { return Settings.settingsQueue.sync { internalValue } }
			set { Settings.settingsQueue.async { self.internalValue = newValue } }
		}
		
		init(_ field: String, defaultValue: T) {
			self.redisField = field
			super.init(wrappedValue: defaultValue)
		}
				
		func readFromRedis(redis: RedisClient) async throws {
			let result = try await redis.readSetting(redisField)
			if let value = T(fromRESP: result) { 
				self.wrappedValue = value
			} 
		}
		
		// Call after setting value
		func writeToRedis(redis: RedisClient) async throws -> Bool {
			return try await redis.hset(redisField, to: wrappedValue, in: "Settings").get()
		}
	}
	
	/// The shared instance for this singleton.
	static let shared = Settings()
		
	/// DispatchQueue to use for thread-safety synchronization.
	fileprivate static let settingsQueue = DispatchQueue(label: "settingsQueue")
	
	/// The ID of the blocked user placeholder.
	@SettingsValue var blockedUserID: UUID = UUID()

	/// The ID of the FriendlyFez user placeholder.
	@SettingsValue var friendlyFezID: UUID = UUID()
	
// MARK: Sections / Features / Apps

	/// Each key-value pair is a feature that's tu
	@StoredSettingsValue("disabledFeatures", defaultValue: DisabledFeaturesGroup(value: [:])) var disabledFeatures: DisabledFeaturesGroup

	/// The name of the onboard Wifi network. Delivered to cients in the notification endpoint.
	@StoredSettingsValue("shipWifiSSID", defaultValue: "NieuwAmsterdam-Guest") var shipWifiSSID: String
	    
// MARK: Limits
	/// The maximum number of alt accounts per primary user account.
	@StoredSettingsValue("maxAlternateAccounts", defaultValue: 6) var maxAlternateAccounts: Int
	
	/// The maximum number of twartts allowed per request.
	@StoredSettingsValue("maximumTwarrts", defaultValue: 200) var maximumTwarrts: Int

	/// The maximum number of twartts allowed per request.
	@StoredSettingsValue("maximumForums", defaultValue: 200) var maximumForums: Int

	/// The maximum number of twartts allowed per request.
	@StoredSettingsValue("maximumForumPosts", defaultValue: 200) var maximumForumPosts: Int

	/// Largest image we allow to be uploaded, in bytes.
	@StoredSettingsValue("maxImageSize", defaultValue: 20 * 1024 * 1024) var maxImageSize: Int

// MARK: Quarantine
	/// The number of reports to trigger forum auto-quarantine.
	@StoredSettingsValue("forumAutoQuarantineThreshold", defaultValue: 3) var forumAutoQuarantineThreshold: Int
	
	/// The number of reports to trigger post/twarrt auto-quarantine.
	@StoredSettingsValue("postAutoQuarantineThreshold", defaultValue: 3) var postAutoQuarantineThreshold: Int
	
	/// The number of reports to trigger user auto-quarantine.
	@StoredSettingsValue("userAutoQuarantineThreshold", defaultValue: 5) var userAutoQuarantineThreshold: Int
	
// MARK: Dates
	/// A Date set to midnight on the day the cruise ship leaves port, in the timezone the ship leaves from. Used by the Events Controller for date arithimetic.
	/// The default here should usually get overwritten in configure.swift.
	@SettingsValue var cruiseStartDate: Date = Calendar.autoupdatingCurrent.date(from: DateComponents(calendar: Calendar.current, 
			timeZone: TimeZone(abbreviation: "EST")!, year: 2022, month: 3, day: 5))!
	
	/// The day of week when the cruise embarks, expressed as number as Calendar's .weekday uses them: Range 1...7, Sunday == 1.
	@SettingsValue var cruiseStartDayOfWeek: Int = 7

	/// The length in days of the cruise, includes partial days. A cruise that embarks on Saturday and returns the next Saturday should have a value of 8.
	@SettingsValue var cruiseLengthInDays: Int = 8

	/// Abbreviation of the time zone that we should display data in.
	@StoredSettingsValue("displayTimeZoneAbbr", defaultValue: "EST") var displayTimeZoneAbbr: String

	/// TimeZone representative of where we departed port from.
	@SettingsValue var portTimeZone: TimeZone = TimeZone(abbreviation: "EST")!
	
// MARK: Images
	/// The  set of image file types that we can parse with the GD library. I believe GD hard-codes these values on install based on what ./configure finds.
	/// If our server app is moved to a new machine after it's built, the valid input types will likely differ.
	@SettingsValue var validImageInputTypes: [String] = []

	/// The  set of image file types that we can create with the GD library. I believe GD hard-codes these values on install based on what ./configure finds.
	/// If our server app is moved to a new machine after it's built, the valid input types will likely differ.
	@SettingsValue var validImageOutputTypes: [String] = []
	
	/// If FALSE, animated images are converted into static jpegs upon upload. Does not affect already uploaded images.
	@StoredSettingsValue("allowAnimatedImages", defaultValue: true) var allowAnimatedImages: Bool
	
// MARK: Directories
	/// Root dir for files used by Swiftarr. The front-end's CSS, JS, static image files, all the Leaf templates are in here,
	/// as are all the seeds files used for database migrations by the backend..
	/// The Resources and Seeds dirs get *copied* into this dir from the root of the git repo by the build system.
	@SettingsValue var staticFilesRootPath: URL = URL(fileURLWithPath: "~")

	/// User uploaded images will be inside this dir. 
	@SettingsValue var userImagesRootPath: URL = URL(fileURLWithPath: "~/swiftarrImages")

	/// Endpoint to call for the API.
	@SettingsValue var apiUrl: URL = URL(string: "http://localhost:8081/api/v3")!

	/// Canonical hostnames for the Twitarr server.
	@SettingsValue var canonicalHostnames: [String] = ["twitarr.com", "joco.hollandamerica.com"]
}

/// Derivative directory paths. These are computed property getters that return a path based on a root path.
/// These properties could be changed into their own roots by making them into their own `@SettingsValue`s.
extension Settings {
	/// Path to the 'admin' directory, inside the 'seeds' directory. Certain seed files can be upload by admin here, and ingested while the server is running.
	var adminDirectoryPath: URL {
		let result = userImagesRootPath.appendingPathComponent("seeds/admin")
		try? FileManager.default.createDirectory(at: result, withIntermediateDirectories: true, attributes: nil)
		return result
	}
	
	/// Path to the 'admin' directory, inside the 'seeds' directory. Certain seed files can be upload by admin here, and ingested while the server is running.
	var seedsDirectoryPath: URL {
		return staticFilesRootPath.appendingPathComponent("seeds")
	}
}

/// Provide one common place for time-related objects.
extension Settings {
	/// TimeZone to use for rendering any time.
	func getDisplayTimeZone() -> TimeZone {
		return TimeZone(abbreviation: displayTimeZoneAbbr) ?? TimeZone.autoupdatingCurrent
	}

	/// Calendar to use for calculating dates (like what day it is).
	/// .current vs .autoupdatingCurrent had some weird implications for TimeZone so I hope
	/// this doesn't do the same here. Time will tell.... pun very much intended.
	func getDisplayCalendar() -> Calendar {
		var cal = Calendar.autoupdatingCurrent
		cal.timeZone = getDisplayTimeZone()
		return cal
	}
}

protocol StoredSetting {
	func readFromRedis(redis: RedisClient) async throws
	func writeToRedis(redis: RedisClient) async throws -> Bool
}

extension Settings {
	// Reads settings from Redis
	func readStoredSettings(app: Application) async throws {
		for child in Mirror(reflecting: self).children {
			guard let storedSetting = child.value as? StoredSetting else {
				continue
			}
			try await storedSetting.readFromRedis(redis: app.redis)
		}
	}
	
	// Stores all settings to Redis
	func storeSettings(on req: Request) async throws {
		for child in Mirror(reflecting: self).children {
			if let storedSetting = child.value as? StoredSetting {
				_ = try await storedSetting.writeToRedis(redis: req.redis)
			}
		}
	}
}

extension Bool: RESPValueConvertible {
	public init?(fromRESP value: RESPValue) {
		self = value.int != 0
	}
	
	public func convertedToRESPValue() -> RESPValue {
		return RESPValue(from: self == true ? 1 : 0)
	}
}

// To maintain thread safety, this 1-value struct needs to be immutable, so that mutating Settings.disabledFeatures
// can only be done by swapping out this entire struct.
struct DisabledFeaturesGroup: Codable, RESPValueConvertible {
	let value: [SwiftarrClientApp : Set<SwiftarrFeature>]
	
	init(value: [SwiftarrClientApp : Set<SwiftarrFeature>]) {
		self.value = value
	}
	
	init?(fromRESP value: RESPValue) {
		guard let encodedData = value.string?.data(using: .utf8), 
				let val = try? JSONDecoder().decode([SwiftarrClientApp : Set<SwiftarrFeature>].self, from: encodedData) else {
			return nil
		}
		self.value = val
	}
	
	func convertedToRESPValue() -> RESPValue {
		guard let encodedData = try? JSONEncoder().encode(value), let encodedStr = String(data: encodedData, encoding: .utf8) else {
			return RESPValue(from: "")
		}
		return RESPValue(from: encodedStr) 
	}
	
	func buildDisabledFeatureArray() -> [DisabledFeature] {
		var result = [DisabledFeature]()
		self.value.forEach { (appName, features) in
			for feature in features {
				result.append(DisabledFeature(appName: appName, featureName: feature))
			}
		}
		return result
	}
}
