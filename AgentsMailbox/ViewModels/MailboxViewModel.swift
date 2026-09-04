import Foundation
import Observation

@MainActor
@Observable
final class MailboxViewModel {
  let settings: AppSettings

  var messages: [MailboxMessage] = []
  var selectedID: MailboxMessage.ID?
  var selectedDetail: MailboxMessageDetail?
  var scope: MailboxScope = .inbox
  var searchText = ""
  var connectionState: MailboxConnectionState = .checking
  var isLoading = false
  var isLoadingDetail = false
  var isLoadingMore = false
  var total: Int?
  var errorMessage: String?
  var settingsPresented = false

  private let api: MailboxAPI
  private let keychain: KeychainStore
  private var nextCursor: String?
  private var token: String?
  private var listGeneration = 0

  init(
    settings: AppSettings = AppSettings(),
    api: MailboxAPI = MailboxAPI(),
    keychain: KeychainStore = KeychainStore()
  ) {
    self.settings = settings
    self.api = api
    self.keychain = keychain
  }

  var hasMore: Bool { nextCursor != nil }

  var selectedMessage: MailboxMessage? {
    guard let selectedID else { return nil }
    return messages.first(where: { $0.id == selectedID })
  }

  func start() async {
    await refresh()
  }

  func refresh() async {
    listGeneration += 1
    let generation = listGeneration
    isLoading = true
    defer { if generation == listGeneration { isLoading = false } }

    do {
      let credentials = try credentials()
      token = credentials.token
      let page = try await api.listMessages(
        baseURL: credentials.baseURL,
        token: credentials.token,
        query: searchText,
        attachmentsOnly: scope == .attachments
      )
      guard generation == listGeneration else { return }
      messages = page.messages
      nextCursor = page.nextCursor
      total = page.total
      connectionState = .connected
      errorMessage = nil

      if let selectedID, messages.contains(where: { $0.id == selectedID }) {
        await loadDetail(id: selectedID)
      } else {
        selectedID = messages.first?.id
        selectedDetail = nil
        if let selectedID { await loadDetail(id: selectedID) }
      }
    } catch MailboxViewModelError.missingCredential {
      guard generation == listGeneration else { return }
      token = nil
      messages = []
      selectedID = nil
      selectedDetail = nil
      connectionState = .needsCredential
      errorMessage = nil
    } catch {
      guard generation == listGeneration else { return }
      connectionState = .offline
      errorMessage = error.localizedDescription
    }
  }

  func select(_ id: MailboxMessage.ID?) async {
    selectedID = id
    selectedDetail = nil
    guard let id else { return }
    await loadDetail(id: id)
  }

  func loadMore() async {
    guard !isLoadingMore, let cursor = nextCursor else { return }
    isLoadingMore = true
    defer { isLoadingMore = false }

    do {
      let credentials = try credentials()
      let page = try await api.listMessages(
        baseURL: credentials.baseURL,
        token: credentials.token,
        query: searchText,
        attachmentsOnly: scope == .attachments,
        cursor: cursor
      )
      messages.append(
        contentsOf: page.messages.filter { next in
          !messages.contains(where: { $0.id == next.id })
        })
      nextCursor = page.nextCursor
      total = page.total ?? total
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func saveConnection(baseURLString: String, account: String, newToken: String) async throws {
    _ = try settings.validatedBaseURL(from: baseURLString)
    let trimmedAccount = account.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedAccount.isEmpty else { throw MailboxConfigurationError.emptyAccount }

    let previousAccount = settings.keychainAccount
    if !newToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      try keychain.saveToken(newToken, account: trimmedAccount)
    } else if trimmedAccount != previousAccount,
      try keychain.readToken(account: trimmedAccount) == nil
    {
      throw MailboxViewModelError.missingCredential
    }

    settings.baseURLString = baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)
    settings.keychainAccount = trimmedAccount
    await refresh()
  }

  func testConnection(baseURLString: String, account: String, candidateToken: String) async throws {
    let baseURL = try settings.validatedBaseURL(from: baseURLString)
    let trimmedAccount = account.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedAccount.isEmpty else { throw MailboxConfigurationError.emptyAccount }
    let proposed = candidateToken.trimmingCharacters(in: .whitespacesAndNewlines)
    let testToken = proposed.isEmpty ? try keychain.readToken(account: trimmedAccount) : proposed
    guard let testToken, !testToken.isEmpty else { throw MailboxViewModelError.missingCredential }
    _ = try await api.listMessages(
      baseURL: baseURL, token: testToken, query: "", attachmentsOnly: false, limit: 1)
  }

  func removeCredential() async throws {
    try keychain.deleteToken(account: settings.keychainAccount)
    token = nil
    await refresh()
  }

  func exportSelectedMessage() async {
    guard let id = selectedID else { return }
    do {
      let credentials = try credentials()
      let data = try await api.rawMessage(
        baseURL: credentials.baseURL, token: credentials.token, id: id)
      let cleanSubject = (selectedMessage?.subject ?? "message")
        .replacingOccurrences(of: "[^A-Za-z0-9._-]+", with: "-", options: .regularExpression)
        .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
      guard
        let url = MailboxExportService.destinationURL(
          suggestedName: "\(cleanSubject.isEmpty ? "message" : cleanSubject).eml")
      else { return }
      try MailboxExportService.write(data, to: url)
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  private func loadDetail(id: String) async {
    isLoadingDetail = true
    defer { isLoadingDetail = false }
    do {
      let credentials = try credentials()
      let detail = try await api.message(
        baseURL: credentials.baseURL, token: credentials.token, id: id)
      guard selectedID == id else { return }
      selectedDetail = detail
      errorMessage = nil
    } catch {
      guard selectedID == id else { return }
      errorMessage = error.localizedDescription
    }
  }

  private func credentials() throws -> (baseURL: URL, token: String) {
    let baseURL = try settings.validatedBaseURL()
    if let token, !token.isEmpty { return (baseURL, token) }
    guard let storedToken = try keychain.readToken(account: settings.keychainAccount),
      !storedToken.isEmpty
    else {
      throw MailboxViewModelError.missingCredential
    }
    return (baseURL, storedToken)
  }
}

enum MailboxViewModelError: LocalizedError {
  case missingCredential

  var errorDescription: String? {
    String(localized: "Add an API token in Settings to connect this mailbox.")
  }
}
