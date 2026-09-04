import Foundation

enum MailboxParser {
  static func page(from data: Data) throws -> MailboxPage {
    let root = try object(from: data)
    let envelope = dictionary(root)
    let rawMessages =
      array(value(in: envelope, keys: ["data", "emails", "messages", "items"]))
      ?? (root as? [Any])
      ?? []
    let messages = rawMessages.compactMap { summary(from: dictionary($0)) }
    let page = dictionary(value(in: envelope, keys: ["page", "pagination", "meta"]))
    let nextCursor = string(value(in: page, keys: ["next_cursor", "nextCursor", "cursor"]))
    let total =
      integer(value(in: page, keys: ["total", "count"]))
      ?? integer(value(in: envelope, keys: ["total", "count"]))
    return MailboxPage(messages: messages, nextCursor: nextCursor, total: total)
  }

  static func detail(from data: Data) throws -> MailboxMessageDetail {
    let root = try object(from: data)
    let envelope = dictionary(root)
    let candidate = value(in: envelope, keys: ["data", "email", "message"])
    let item = dictionary(candidate) ?? envelope
    let addressFields = dictionary(value(in: item, keys: ["addresses"]))
    guard let id = string(value(in: item, keys: ["id", "message_id", "messageId"])) else {
      throw MailboxAPIError.invalidResponse
    }

    return MailboxMessageDetail(
      id: id,
      subject: normalizedSubject(string(value(in: item, keys: ["subject"]))),
      sender: address(value(in: item, keys: ["from", "sender"]))
        ?? MailboxAddress(name: nil, address: String(localized: "Unknown sender")),
      recipients: addresses(value(in: item, keys: ["to", "recipients"])),
      cc: addresses(value(in: item, keys: ["cc"]))
        + addresses(value(in: addressFields, keys: ["cc"])),
      receivedAt: date(value(in: item, keys: ["received_at", "receivedAt", "date", "created_at"])),
      textBody: string(
        value(in: item, keys: ["text", "text_body", "textBody", "body_text", "body"])),
      htmlBody: string(value(in: item, keys: ["html", "html_body", "htmlBody", "body_html"])),
      attachments: attachments(value(in: item, keys: ["attachments"])),
      headers: headers(value(in: item, keys: ["headers"]))
    )
  }

  private static func summary(from item: [String: Any]?) -> MailboxMessage? {
    guard
      let item,
      let id = string(value(in: item, keys: ["id", "message_id", "messageId"]))
    else { return nil }

    let attachmentItems = attachments(value(in: item, keys: ["attachments"]))
    let attachmentCount =
      integer(value(in: item, keys: ["attachment_count", "attachmentCount"])) ?? 0
    return MailboxMessage(
      id: id,
      subject: normalizedSubject(string(value(in: item, keys: ["subject"]))),
      sender: address(value(in: item, keys: ["from", "sender"]))
        ?? MailboxAddress(name: nil, address: String(localized: "Unknown sender")),
      recipients: addresses(value(in: item, keys: ["to", "recipients"])),
      receivedAt: date(value(in: item, keys: ["received_at", "receivedAt", "date", "created_at"])),
      snippet: string(
        value(in: item, keys: ["snippet", "preview", "text_preview", "body_preview"])) ?? "",
      hasAttachments: boolean(value(in: item, keys: ["has_attachments", "hasAttachments"]))
        ?? (attachmentCount > 0 || !attachmentItems.isEmpty)
    )
  }

  private static func object(from data: Data) throws -> Any {
    do {
      return try JSONSerialization.jsonObject(with: data)
    } catch {
      throw MailboxAPIError.invalidResponse
    }
  }

  private static func value(in dictionary: [String: Any]?, keys: [String]) -> Any? {
    guard let dictionary else { return nil }
    for key in keys where dictionary[key] != nil { return dictionary[key] }
    return nil
  }

  private static func dictionary(_ value: Any?) -> [String: Any]? {
    value as? [String: Any]
  }

  private static func array(_ value: Any?) -> [Any]? {
    value as? [Any]
  }

  private static func string(_ value: Any?) -> String? {
    if let value = value as? String { return value }
    if let value = value as? NSNumber { return value.stringValue }
    return nil
  }

  private static func integer(_ value: Any?) -> Int? {
    if let value = value as? Int { return value }
    if let value = value as? NSNumber { return value.intValue }
    if let value = value as? String { return Int(value) }
    return nil
  }

  private static func boolean(_ value: Any?) -> Bool? {
    if let value = value as? Bool { return value }
    if let value = value as? NSNumber { return value.boolValue }
    if let value = value as? String {
      return ["true", "1", "yes"].contains(value.lowercased())
    }
    return nil
  }

  private static func normalizedSubject(_ value: String?) -> String {
    guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
      return String(localized: "No subject")
    }
    return value
  }

  private static func address(_ rawValue: Any?) -> MailboxAddress? {
    if let raw = string(rawValue)?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty {
      if let opening = raw.lastIndex(of: "<"), let closing = raw.lastIndex(of: ">"),
        opening < closing
      {
        let name = raw[..<opening].trimmingCharacters(
          in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: "\"")))
        let address = raw[raw.index(after: opening)..<closing].trimmingCharacters(
          in: .whitespacesAndNewlines)
        return MailboxAddress(name: name.isEmpty ? nil : name, address: address)
      }
      return MailboxAddress(name: nil, address: raw)
    }
    if let item = dictionary(rawValue) {
      let email = string(value(in: item, keys: ["address", "email", "value"])) ?? ""
      let name = string(value(in: item, keys: ["name", "display_name", "displayName"]))
      if !email.isEmpty { return MailboxAddress(name: name, address: email) }
    }
    return nil
  }

  private static func addresses(_ value: Any?) -> [MailboxAddress] {
    if let rawItems = array(value) { return rawItems.compactMap(address) }
    if let raw = string(value) {
      return raw.split(separator: ",").compactMap { address(String($0)) }
    }
    return address(value).map { [$0] } ?? []
  }

  private static func attachments(_ rawValue: Any?) -> [MailboxAttachment] {
    guard let items = array(rawValue) else { return [] }
    return items.enumerated().compactMap { index, raw -> MailboxAttachment? in
      if let filename = string(raw), !filename.isEmpty {
        return MailboxAttachment(
          id: "attachment-\(index)-\(filename)", filename: filename, contentType: nil, size: nil)
      }
      guard let item = dictionary(raw) else { return nil }
      let filename =
        string(value(in: item, keys: ["filename", "name"])) ?? String(localized: "Attachment")
      let id =
        string(value(in: item, keys: ["id", "attachment_id", "attachmentId"]))
        ?? "attachment-\(index)-\(filename)"
      return MailboxAttachment(
        id: id,
        filename: filename,
        contentType: string(value(in: item, keys: ["content_type", "contentType", "mime_type"])),
        size: integer(value(in: item, keys: ["size", "size_bytes", "sizeBytes"]))
      )
    }
  }

  private static func headers(_ value: Any?) -> [String: String] {
    guard let dictionary = dictionary(value) else { return [:] }
    return dictionary.reduce(into: [:]) { result, item in
      if let value = string(item.value) { result[item.key] = value }
    }
  }

  private static func date(_ value: Any?) -> Date? {
    guard let raw = string(value), !raw.isEmpty else { return nil }

    let fractional = ISO8601DateFormatter()
    fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = fractional.date(from: raw) { return date }

    let standard = ISO8601DateFormatter()
    if let date = standard.date(from: raw) { return date }

    for format in ["EEE, dd MMM yyyy HH:mm:ss Z", "dd MMM yyyy HH:mm:ss Z"] {
      let formatter = DateFormatter()
      formatter.locale = Locale(identifier: "en_US_POSIX")
      formatter.dateFormat = format
      if let date = formatter.date(from: raw) { return date }
    }
    return nil
  }
}
