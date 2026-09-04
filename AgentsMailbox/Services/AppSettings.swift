import Foundation
import Observation

@MainActor
@Observable
final class AppSettings {
  nonisolated static let defaultBaseURL = "https://api.agents.hongyu.dev"
  nonisolated static let defaultKeychainAccount = "codex-agent"
  nonisolated static let keychainService = "agents.hongyu.dev-mailbox-api"

  private enum Key {
    static let baseURL = "mailbox.baseURL"
    static let keychainAccount = "mailbox.keychainAccount"
  }

  private let defaults: UserDefaults

  var baseURLString: String {
    didSet { defaults.set(baseURLString, forKey: Key.baseURL) }
  }

  var keychainAccount: String {
    didSet { defaults.set(keychainAccount, forKey: Key.keychainAccount) }
  }

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    baseURLString = defaults.string(forKey: Key.baseURL) ?? Self.defaultBaseURL
    keychainAccount = defaults.string(forKey: Key.keychainAccount) ?? Self.defaultKeychainAccount
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
  case emptyAccount

  var errorDescription: String? {
    switch self {
    case .invalidBaseURL:
      String(localized: "Enter a valid HTTP or HTTPS API URL.")
    case .emptyAccount:
      String(localized: "Enter a Keychain account name.")
    }
  }
}
