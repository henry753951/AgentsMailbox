import Foundation
import Security

struct KeychainStore: Sendable {
  let service: String

  init(service: String = AppSettings.keychainService) {
    self.service = service
  }

  func readToken(account: String) throws -> String? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]

    var result: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    if status == errSecItemNotFound { return nil }
    guard status == errSecSuccess else { throw KeychainError.status(status) }
    guard let data = result as? Data, let token = String(data: data, encoding: .utf8) else {
      throw KeychainError.invalidData
    }
    return token
  }

  func saveToken(_ token: String, account: String) throws {
    let trimmedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedToken.isEmpty else { throw KeychainError.emptyToken }

    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
    ]
    let attributes: [String: Any] = [
      kSecValueData as String: Data(trimmedToken.utf8),
      kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
    ]

    let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
    if updateStatus == errSecItemNotFound {
      var addQuery = query
      for (key, value) in attributes {
        addQuery[key] = value
      }
      let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
      guard addStatus == errSecSuccess else { throw KeychainError.status(addStatus) }
    } else if updateStatus != errSecSuccess {
      throw KeychainError.status(updateStatus)
    }
  }

  func deleteToken(account: String) throws {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
    ]
    let status = SecItemDelete(query as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw KeychainError.status(status)
    }
  }
}

enum KeychainError: LocalizedError {
  case status(OSStatus)
  case invalidData
  case emptyToken

  var errorDescription: String? {
    switch self {
    case .status(let status):
      if let message = SecCopyErrorMessageString(status, nil) as String? {
        return String(localized: "Keychain error: \(message)")
      }
      return String(localized: "Keychain could not complete the request.")
    case .invalidData:
      return String(localized: "The saved credential is not valid text.")
    case .emptyToken:
      return String(localized: "Enter an API token.")
    }
  }
}
