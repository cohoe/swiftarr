
/// The status of a time warp.

public enum TimeWarpStatus: String, Codable {
	/// In the future.
	case scheduled
	/// The warp was successful.
	case success
	/// An error occurred.
	case error
	/// The warp was canceled before it triggered.
	case canceled
}
