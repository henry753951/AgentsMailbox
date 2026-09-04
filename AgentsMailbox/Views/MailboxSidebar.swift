import SwiftUI

struct MailboxSidebar: View {
  @Bindable var model: MailboxViewModel

  var body: some View {
    VStack(spacing: 0) {
      List(selection: $model.scope) {
        Section("Mailboxes") {
          Label("Inbox", systemImage: "tray")
            .badge(model.inboxTotal ?? 0)
            .tag(MailboxScope.inbox)

          Label("Attachments", systemImage: "paperclip")
            .tag(MailboxScope.attachments)
        }
      }
      .listStyle(.sidebar)
      .onChange(of: model.scope) {
        Task { await model.refresh() }
      }

      Divider()

      VStack(alignment: .leading, spacing: 9) {
        SettingsLink {
          Label("Settings", systemImage: "gearshape")
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)

        HStack(spacing: 7) {
          Circle()
            .fill(statusColor)
            .frame(width: 7, height: 7)
          Text(statusText)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      .padding(.horizontal, 13)
      .padding(.vertical, 11)
    }
    .navigationTitle("Agents Mailbox")
  }

  private var statusText: LocalizedStringKey {
    switch model.connectionState {
    case .checking: "Checking connection"
    case .connected: "Connected"
    case .needsCredential: "Setup required"
    case .offline: "Unavailable"
    }
  }

  private var statusColor: Color {
    switch model.connectionState {
    case .checking: .orange
    case .connected: .green
    case .needsCredential: .orange
    case .offline: .red
    }
  }
}
