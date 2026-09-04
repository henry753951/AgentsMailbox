import AppKit
import Foundation
import UniformTypeIdentifiers

@MainActor
enum MailboxExportService {
  static func destinationURL(suggestedName: String) -> URL? {
    let panel = NSSavePanel()
    panel.allowedContentTypes = [.emailMessage]
    panel.canCreateDirectories = true
    panel.nameFieldStringValue = suggestedName
    panel.title = String(localized: "Save Original Message")
    panel.prompt = String(localized: "Save")
    return panel.runModal() == .OK ? panel.url : nil
  }

  static func write(_ data: Data, to url: URL) throws {
    try data.write(to: url, options: .atomic)
  }
}
