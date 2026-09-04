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
    .frame(width: 610, height: 500)
  }
}

private struct ConnectionSettingsView: View {
  @Bindable var model: MailboxViewModel
  @State private var baseURLString = ""
  @State private var account = ""
  @State private var candidateToken = ""
  @State private var statusMessage: String?
  @State private var statusIsError = false
  @State private var isWorking = false
  @State private var confirmsRemoval = false

  var body: some View {
    ZStack {
      MailboxBackground()
      ScrollView {
        VStack(alignment: .leading, spacing: 22) {
          VStack(alignment: .leading, spacing: 6) {
            Text("Mailbox Connection")
              .font(.title2.weight(.semibold))
            Text("The API URL is saved in Preferences. Your token stays in the macOS Keychain.")
              .foregroundStyle(.secondary)
          }

          VStack(alignment: .leading, spacing: 16) {
            SettingsField(title: "API URL", detail: "The base address of the mailbox API.") {
              TextField("https://api.example.com", text: $baseURLString)
                .textFieldStyle(.roundedBorder)
            }

            SettingsField(
              title: "Keychain Account", detail: "Used to find this mailbox credential in Keychain."
            ) {
              TextField("codex-agent", text: $account)
                .textFieldStyle(.roundedBorder)
            }

            SettingsField(
              title: "Bearer Token",
              detail: "Leave blank to keep the credential already saved for this account."
            ) {
              SecureField("API token", text: $candidateToken)
                .textFieldStyle(.roundedBorder)
            }

            HStack(spacing: 8) {
              Image(systemName: "key.fill")
                .foregroundStyle(MailboxPalette.blue)
              Text("Keychain service")
                .foregroundStyle(.secondary)
              Text(AppSettings.keychainService)
                .font(.callout.monospaced())
                .textSelection(.enabled)
            }
            .font(.callout)
          }
          .padding(20)
          .mailboxGlassCard(radius: 20)

          if let statusMessage {
            Label(
              statusMessage,
              systemImage: statusIsError ? "exclamationmark.circle.fill" : "checkmark.circle.fill"
            )
            .foregroundStyle(statusIsError ? Color.red : Color.green)
            .font(.callout)
          }

          HStack {
            Button("Remove Token", role: .destructive) { confirmsRemoval = true }
              .disabled(isWorking)
            Spacer()
            Button("Test Connection") { testConnection() }
              .disabled(isWorking)
              .mailboxGlassButton()
            Button("Save") { save() }
              .keyboardShortcut(.defaultAction)
              .disabled(isWorking)
              .mailboxGlassButton(prominent: true)
          }
        }
        .frame(maxWidth: 540)
        .padding(28)
        .frame(maxWidth: .infinity)
      }
    }
    .onAppear {
      baseURLString = model.settings.baseURLString
      account = model.settings.keychainAccount
    }
    .alert("Remove API Token?", isPresented: $confirmsRemoval) {
      Button("Cancel", role: .cancel) {}
      Button("Remove", role: .destructive) { removeToken() }
    } message: {
      Text("The token will be deleted from Keychain. The mailbox API URL will remain saved.")
    }
  }

  private func testConnection() {
    isWorking = true
    statusMessage = nil
    Task {
      defer { isWorking = false }
      do {
        try await model.testConnection(
          baseURLString: baseURLString, account: account, candidateToken: candidateToken)
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
          baseURLString: baseURLString, account: account, newToken: candidateToken)
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
      do {
        try await model.removeCredential()
        candidateToken = ""
        statusIsError = false
        statusMessage = String(localized: "The token was removed from Keychain.")
      } catch {
        statusIsError = true
        statusMessage = error.localizedDescription
      }
    }
  }
}

private struct SettingsField<Content: View>: View {
  let title: LocalizedStringKey
  let detail: LocalizedStringKey
  @ViewBuilder let content: Content

  var body: some View {
    VStack(alignment: .leading, spacing: 7) {
      Text(title).font(.headline)
      Text(detail)
        .font(.caption)
        .foregroundStyle(.secondary)
      content
    }
  }
}

private struct AboutSettingsView: View {
  @State private var isShowingLicenses = false

  var body: some View {
    ZStack {
      MailboxBackground()
      VStack(spacing: 18) {
        MailboxMark(size: 82)
        VStack(spacing: 5) {
          Text("Agents Mailbox")
            .font(.title.weight(.semibold))
          Text("A small, read-only macOS client for an Agents Mailbox inbox.")
            .foregroundStyle(.secondary)
        }
        Text(
          "Messages are treated as untrusted content. This app does not send, reply to, delete, or mark mail, and it does not load remote HTML resources."
        )
        .multilineTextAlignment(.center)
        .foregroundStyle(.secondary)
        .frame(maxWidth: 420)
        Button {
          isShowingLicenses = true
        } label: {
          Label("Open-Source Licenses", systemImage: "doc.text")
        }
        .mailboxGlassButton()
        Text(versionDescription)
          .font(.caption)
          .foregroundStyle(.tertiary)
      }
      .padding(36)
      .mailboxGlassCard(tint: MailboxPalette.blue.opacity(0.035), radius: 26)
    }
    .padding(28)
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
