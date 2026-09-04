import Foundation

struct MailboxAddress: Hashable, Sendable {
  var name: String?
  var address: String

  var displayName: String {
    let trimmedName = name?.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmedName?.isEmpty == false ? trimmedName! : address
  }
}

struct MailboxAttachment: Identifiable, Hashable, Sendable {
  var id: String
  var filename: String
  var contentType: String?
  var size: Int?
}

struct MailboxMessage: Identifiable, Hashable, Sendable {
  var id: String
  var subject: String
  var sender: MailboxAddress
  var recipients: [MailboxAddress]
  var receivedAt: Date?
  var snippet: String
  var hasAttachments: Bool

  var senderInitials: String {
    let components = sender.displayName
      .split(whereSeparator: { $0.isWhitespace || $0 == "@" || $0 == "." })
      .prefix(2)
    let initials = components.compactMap(\.first).map(String.init).joined()
    return initials.isEmpty ? "?" : initials.uppercased()
  }
}

struct MailboxMessageDetail: Identifiable, Hashable, Sendable {
  var id: String
  var subject: String
  var sender: MailboxAddress
  var recipients: [MailboxAddress]
  var cc: [MailboxAddress]
  var receivedAt: Date?
  var textBody: String?
  var htmlBody: String?
  var attachments: [MailboxAttachment]
  var headers: [String: String]

  var readableBody: String {
    if let textBody = textBody?.trimmingCharacters(in: .whitespacesAndNewlines), !textBody.isEmpty {
      return textBody
    }
    if let htmlBody, !htmlBody.isEmpty {
      return
        htmlBody
        .replacingOccurrences(of: "<br\\s*/?>", with: "\n", options: .regularExpression)
        .replacingOccurrences(
          of: "</p>", with: "\n\n", options: [.regularExpression, .caseInsensitive]
        )
        .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        .replacingOccurrences(of: "&nbsp;", with: " ")
        .replacingOccurrences(of: "&amp;", with: "&")
        .replacingOccurrences(of: "&lt;", with: "<")
        .replacingOccurrences(of: "&gt;", with: ">")
        .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    return ""
  }
}

struct MailboxPage: Sendable {
  var messages: [MailboxMessage]
  var nextCursor: String?
  var total: Int?
}

enum MailboxScope: String, CaseIterable, Identifiable, Sendable {
  case inbox
  case attachments

  var id: Self { self }
}

enum MailboxConnectionState: Equatable, Sendable {
  case checking
  case connected
  case needsCredential
  case offline
}
