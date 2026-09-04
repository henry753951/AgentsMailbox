import SwiftUI

struct MessageListView: View {
  @Bindable var model: MailboxViewModel

  var body: some View {
    ZStack {
      Color(nsColor: .controlBackgroundColor)
        .ignoresSafeArea()

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
    ContentUnavailableView {
      Label("Connect your mailbox", systemImage: "tray")
    } description: {
      Text("Add the API URL and token in Settings.")
    } actions: {
      SettingsLink {
        Text("Open Settings")
      }
    }
  }
}

struct MessageRow: View {
  let message: MailboxMessage

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: "person.crop.circle.fill")
        .font(.system(size: 34, weight: .regular))
        .symbolRenderingMode(.hierarchical)
        .foregroundStyle(.secondary)
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
