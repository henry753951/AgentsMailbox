import AppKit
import SwiftUI

struct SettingsView: View {
  @Bindable var model: MailboxViewModel

  var body: some View {
    TabView {
      ConnectionSettingsView(model: model)
        .tabItem { Label("Connection", systemImage: "network") }

      AboutSettingsView()
        .tabItem { Label("About", systemImage: "info.circle") }
    }
    .frame(width: 560, height: 300)
  }
}

private struct ConnectionSettingsView: View {
  @Bindable var model: MailboxViewModel
  @State private var baseURLString = ""
  @State private var candidateToken = ""
  @State private var statusMessage: String?
  @State private var statusIsError = false
  @State private var isWorking = false
  @State private var confirmsRemoval = false

  var body: some View {
    Form {
      Section("Connection") {
        TextField("API URL", text: $baseURLString)
        SecureField("Bearer Token", text: $candidateToken)

        Text(
          "The token is stored in this Mac’s app preferences. Leave it blank to keep the saved token."
        )
        .font(.caption)
        .foregroundStyle(.secondary)
      }

      if let statusMessage {
        Section {
          Label(
            statusMessage,
            systemImage: statusIsError ? "exclamationmark.circle.fill" : "checkmark.circle.fill"
          )
          .foregroundStyle(statusIsError ? Color.red : Color.green)
        }
      }

      Section {
        HStack {
          Button("Remove Token", role: .destructive) { confirmsRemoval = true }
            .disabled(isWorking)
          Spacer()
          Button("Test Connection") { testConnection() }
            .disabled(isWorking)
          Button("Save") { save() }
            .keyboardShortcut(.defaultAction)
            .disabled(isWorking)
        }
      }
    }
    .formStyle(.grouped)
    .onAppear {
      baseURLString = model.settings.baseURLString
    }
    .alert("Remove API Token?", isPresented: $confirmsRemoval) {
      Button("Cancel", role: .cancel) {}
      Button("Remove", role: .destructive) { removeToken() }
    } message: {
      Text("The saved token will be removed. The mailbox API URL will remain saved.")
    }
  }

  private func testConnection() {
    isWorking = true
    statusMessage = nil
    Task {
      defer { isWorking = false }
      do {
        try await model.testConnection(
          baseURLString: baseURLString, candidateToken: candidateToken)
        statusIsError = false
        statusMessage = String(localized: "Connection succeeded.")
      } catch {
        statusIsError = true
        statusMessage = error.localizedDescription
      }
    }
  }

  private func save() {
    isWorking = true
    statusMessage = nil
    Task {
      defer { isWorking = false }
      do {
        try await model.saveConnection(
          baseURLString: baseURLString, newToken: candidateToken)
        candidateToken = ""
        statusIsError = false
        statusMessage = String(localized: "Connection settings saved.")
      } catch {
        statusIsError = true
        statusMessage = error.localizedDescription
      }
    }
  }

  private func removeToken() {
    isWorking = true
    statusMessage = nil
    Task {
      defer { isWorking = false }
      await model.removeCredential()
      candidateToken = ""
      statusIsError = false
      statusMessage = String(localized: "The saved token was removed.")
    }
  }
}

private struct AboutSettingsView: View {
  @State private var isShowingLicenses = false

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 22) {
        HStack(spacing: 16) {
          Image(nsImage: NSApplication.shared.applicationIconImage)
            .resizable()
            .interpolation(.high)
            .frame(width: 68, height: 68)
          VStack(alignment: .leading, spacing: 4) {
            Text("Agents Mailbox")
              .font(.title2.weight(.semibold))
            Text(versionDescription)
              .foregroundStyle(.secondary)
          }
        }

        Text("A small, read-only macOS client for an Agents Mailbox inbox.")
          .foregroundStyle(.secondary)

        Text(
          "Messages are treated as untrusted content. This app does not send, reply to, delete, or mark mail, and it does not load remote HTML resources."
        )
        .foregroundStyle(.secondary)

        Button {
          isShowingLicenses = true
        } label: {
          Label("Open-Source Licenses", systemImage: "doc.text")
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(14)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
      }
      .frame(maxWidth: 470, alignment: .leading)
      .padding(28)
      .frame(maxWidth: .infinity)
    }
    .sheet(isPresented: $isShowingLicenses) {
      LicenseTextView()
    }
  }

  private var versionDescription: String {
    let version =
      Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    return String(localized: "Version \(version) (\(build))")
  }
}

private struct LicenseTextView: View {
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      ScrollView {
        Text(licenseText)
          .font(.system(.callout, design: .monospaced))
          .textSelection(.enabled)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(24)
      }
      .navigationTitle("Open-Source Licenses")
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") { dismiss() }
        }
      }
    }
    .frame(width: 680, height: 580)
  }

  private var licenseText: String {
    guard
      let url = Bundle.main.url(forResource: "ThirdPartyNotices", withExtension: "txt"),
      let text = try? String(contentsOf: url, encoding: .utf8)
    else { return String(localized: "License information is unavailable.") }
    return text
  }
}
