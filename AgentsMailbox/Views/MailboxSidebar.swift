import SwiftUI

struct MailboxSidebar: View {
  @Bindable var model: MailboxViewModel

  var body: some View {
    VStack(spacing: 0) {
      List {
        Section {
          sidebarRow(scope: .inbox, title: "Inbox", symbol: "tray.full", count: model.inboxTotal)
          sidebarRow(scope: .attachments, title: "Attachments", symbol: "paperclip", count: nil)
        }
      }
      .listStyle(.sidebar)

      VStack(alignment: .leading, spacing: 10) {
        Divider()
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
      .padding(.horizontal, 14)
      .padding(.bottom, 12)
    }
    .navigationTitle("Agents Mailbox")
  }

  private func sidebarRow(
    scope: MailboxScope, title: LocalizedStringKey, symbol: String, count: Int?
  ) -> some View {
    Button {
      guard model.scope != scope else { return }
      model.scope = scope
      Task { await model.refresh() }
    } label: {
      HStack {
        Label(title, systemImage: symbol)
        Spacer()
        if let count {
          Text(count, format: .number)
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
        }
      }
    }
    .listRowBackground(model.scope == scope ? Color.accentColor.opacity(0.16) : Color.clear)
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
