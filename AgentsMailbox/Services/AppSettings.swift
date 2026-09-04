import Foundation
import Observation

@MainActor
@Observable
final class AppSettings {
  nonisolated static let defaultBaseURL = "https://api.agents.hongyu.dev"

  private enum Key {
    static let baseURL = "mailbox.baseURL"
    static let token = "mailbox.token"
  }

  private let defaults: UserDefaults

  var baseURLString: String {
    didSet { defaults.set(baseURLString, forKey: Key.baseURL) }
  }

  var token: String {
    didSet { defaults.set(token, forKey: Key.token) }
  }

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    baseURLString = defaults.string(forKey: Key.baseURL) ?? Self.defaultBaseURL
    token = defaults.string(forKey: Key.token) ?? ""
  }

  func validatedBaseURL(from candidate: String? = nil) throws -> URL {
    let rawValue = (candidate ?? baseURLString).trimmingCharacters(in: .whitespacesAndNewlines)
    guard
      let components = URLComponents(string: rawValue),
      let scheme = components.scheme?.lowercased(),
      ["http", "https"].contains(scheme),
      components.host?.isEmpty == false,
      let url = components.url
    else {
      throw MailboxConfigurationError.invalidBaseURL
    }
    return url
  }
}

enum MailboxConfigurationError: LocalizedError {
  case invalidBaseURL

  var errorDescription: String? {
    switch self {
    case .invalidBaseURL:
      String(localized: "Enter a valid HTTP or HTTPS API URL.")
    }
  }
}
