import Foundation

actor MailboxAPI {
  private let session: URLSession

  init() {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
    configuration.urlCache = nil
    configuration.httpCookieStorage = nil
    configuration.httpShouldSetCookies = false
    session = URLSession(configuration: configuration)
  }

  func listMessages(
    baseURL: URL,
    token: String,
    query: String,
    attachmentsOnly: Bool,
    cursor: String? = nil,
    limit: Int = 50
  ) async throws -> MailboxPage {
    var components = URLComponents(
      url: endpoint(baseURL, components: ["v1", "emails"]), resolvingAgainstBaseURL: false)
    var items = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "view", value: "compact"),
      URLQueryItem(name: "include_count", value: "true"),
    ]
    let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
    if !normalizedQuery.isEmpty { items.append(URLQueryItem(name: "q", value: normalizedQuery)) }
    if attachmentsOnly { items.append(URLQueryItem(name: "has_attachments", value: "true")) }
    if let cursor, !cursor.isEmpty { items.append(URLQueryItem(name: "cursor", value: cursor)) }
    components?.queryItems = items
    guard let url = components?.url else { throw MailboxAPIError.invalidURL }

    let data = try await execute(authorizedRequest(url: url, token: token))
    return try MailboxParser.page(from: data)
  }

  func message(baseURL: URL, token: String, id: String) async throws -> MailboxMessageDetail {
    guard id.range(of: "^[A-Za-z0-9._~-]+$", options: .regularExpression) != nil else {
      throw MailboxAPIError.invalidMessageIdentifier
    }
    let url = endpoint(baseURL, components: ["v1", "emails", id])
    let data = try await execute(authorizedRequest(url: url, token: token))
    return try MailboxParser.detail(from: data)
  }

  func rawMessage(baseURL: URL, token: String, id: String) async throws -> Data {
    guard id.range(of: "^[A-Za-z0-9._~-]+$", options: .regularExpression) != nil else {
      throw MailboxAPIError.invalidMessageIdentifier
    }
    let url = endpoint(baseURL, components: ["v1", "emails", id, "raw"])
    return try await execute(authorizedRequest(url: url, token: token))
  }

  private func endpoint(_ baseURL: URL, components: [String]) -> URL {
    components.reduce(baseURL) { url, component in
      url.appendingPathComponent(component)
    }
  }

  private func authorizedRequest(url: URL, token: String) -> URLRequest {
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.timeoutInterval = 30
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json, message/rfc822", forHTTPHeaderField: "Accept")
    return request
  }

  private func execute(_ request: URLRequest) async throws -> Data {
    do {
      let (data, response) = try await session.data(for: request)
      guard let response = response as? HTTPURLResponse else {
        throw MailboxAPIError.invalidResponse
      }
      switch response.statusCode {
      case 200..<300:
        return data
      case 401, 403:
        throw MailboxAPIError.unauthorized
      case 404:
        throw MailboxAPIError.notFound
      default:
        throw MailboxAPIError.server(status: response.statusCode)
      }
    } catch let error as MailboxAPIError {
      throw error
    } catch {
      throw MailboxAPIError.transport(error.localizedDescription)
    }
  }
}

enum MailboxAPIError: LocalizedError, Sendable {
  case invalidURL
  case invalidMessageIdentifier
  case invalidResponse
  case unauthorized
  case notFound
  case server(status: Int)
  case transport(String)

  var errorDescription: String? {
    switch self {
    case .invalidURL:
      String(localized: "The API URL could not be created.")
    case .invalidMessageIdentifier:
      String(localized: "The message identifier is invalid.")
    case .invalidResponse:
      String(localized: "The mailbox returned an unreadable response.")
    case .unauthorized:
      String(localized: "The API token was not accepted.")
    case .notFound:
      String(localized: "The requested message was not found.")
    case .server(let status):
      String(localized: "The mailbox service returned status \(status).")
    case .transport(let message):
      String(localized: "Could not reach the mailbox: \(message)")
    }
  }
}
