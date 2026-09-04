import SwiftUI

struct MessageListView: View {
  @Bindable var model: MailboxViewModel

  var body: some View {
    ZStack {
      MailboxBackground()

      if model.connectionState == .needsCredential {
        ConnectionRequiredView()
      } else if model.isLoading, model.messages.isEmpty {
        ProgressView("Loading messages…")
          .controlSize(.large)
      } else if model.messages.isEmpty {
        ContentUnavailableView(
          model.searchText.isEmpty ? "No messages" : "No results",
          systemImage: model.searchText.isEmpty ? "tray" : "magnifyingglass",
          description: Text(
            model.searchText.isEmpty ? "New mail will appear here." : "Try a different search.")
        )
      } else {
        List(selection: $model.selectedID) {
          ForEach(model.messages) { message in
            MessageRow(message: message)
              .tag(message.id)
          }

          if model.hasMore {
            Button {
              Task { await model.loadMore() }
            } label: {
              HStack {
                Spacer()
                if model.isLoadingMore { ProgressView().controlSize(.small) }
                Text("Load More")
                Spacer()
              }
              .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .disabled(model.isLoadingMore)
          }
        }
        .scrollContentBackground(.hidden)
        .listStyle(.inset)
        .onChange(of: model.selectedID) { _, id in
          Task { await model.select(id) }
        }
      }
    }
    .navigationTitle(model.scope == .inbox ? "Inbox" : "Attachments")
  }
}

private struct ConnectionRequiredView: View {
  var body: some View {
    VStack(spacing: 16) {
      MailboxMark(size: 60)
      Text("Connect your mailbox")
        .font(.title3.weight(.semibold))
      Text("Add the API URL and token in Settings. The token is stored in your Mac’s Keychain.")
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .frame(maxWidth: 280)
      SettingsLink {
        Text("Open Settings")
      }
      .mailboxGlassButton(prominent: true)
    }
    .padding(30)
    .mailboxGlassCard(tint: MailboxPalette.blue.opacity(0.04), radius: 24)
    .padding(24)
  }
}

struct MessageRow: View {
  let message: MailboxMessage

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      ZStack {
        Circle()
          .fill(
            LinearGradient(
              colors: [MailboxPalette.blue.opacity(0.9), MailboxPalette.violet.opacity(0.9)],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
        Text(message.senderInitials)
          .font(.caption.weight(.bold))
          .foregroundStyle(.white)
      }
      .frame(width: 36, height: 36)

      VStack(alignment: .leading, spacing: 4) {
        HStack(alignment: .firstTextBaseline) {
          Text(message.sender.displayName)
            .font(.callout.weight(.semibold))
            .lineLimit(1)
          Spacer(minLength: 8)
          if let receivedAt = message.receivedAt {
            Text(receivedAt, format: .dateTime.month(.abbreviated).day().hour().minute())
              .font(.caption2)
              .foregroundStyle(.tertiary)
          }
        }

        HStack(spacing: 5) {
          Text(message.subject)
            .font(.callout)
            .lineLimit(1)
          if message.hasAttachments {
            Image(systemName: "paperclip")
              .font(.caption2)
              .foregroundStyle(.secondary)
          }
        }

        if !message.snippet.isEmpty {
          Text(message.snippet)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(2)
        }
      }
    }
    .padding(.vertical, 8)
  }
}
