import SwiftUI

struct MessageDetailView: View {
  @Bindable var model: MailboxViewModel

  var body: some View {
    ZStack {
      MailboxBackground()

      if model.isLoadingDetail {
        ProgressView("Loading message…")
          .controlSize(.large)
      } else if let detail = model.selectedDetail {
        ScrollView {
          VStack(alignment: .leading, spacing: 18) {
            messageHeader(detail)
            addressCard(detail)

            if !detail.attachments.isEmpty {
              attachmentCard(detail.attachments)
            }

            bodyCard(detail)
          }
          .frame(maxWidth: 820, alignment: .leading)
          .padding(28)
          .frame(maxWidth: .infinity)
        }
      } else {
        ContentUnavailableView(
          "Select a message",
          systemImage: "envelope.open",
          description: Text("Choose a message from the list to read it.")
        )
      }
    }
  }

  private func messageHeader(_ detail: MailboxMessageDetail) -> some View {
    HStack(alignment: .top, spacing: 16) {
      MailboxMark(size: 52)
      VStack(alignment: .leading, spacing: 7) {
        Text(detail.subject)
          .font(.title2.weight(.semibold))
          .textSelection(.enabled)
        HStack(spacing: 7) {
          Text(detail.sender.displayName)
            .font(.headline)
          if detail.sender.displayName != detail.sender.address {
            Text(detail.sender.address)
              .foregroundStyle(.secondary)
          }
        }
        .textSelection(.enabled)
        if let date = detail.receivedAt {
          Text(date, format: .dateTime.weekday(.wide).month(.wide).day().year().hour().minute())
            .font(.callout)
            .foregroundStyle(.secondary)
        }
      }
      Spacer(minLength: 12)
      Button {
        Task { await model.exportSelectedMessage() }
      } label: {
        Label("Save EML", systemImage: "arrow.down.doc")
      }
      .mailboxGlassButton()
    }
  }

  private func addressCard(_ detail: MailboxMessageDetail) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      AddressLine(title: "From", addresses: [detail.sender])
      AddressLine(title: "To", addresses: detail.recipients)
      if !detail.cc.isEmpty { AddressLine(title: "Cc", addresses: detail.cc) }
    }
    .padding(16)
    .mailboxGlassCard(radius: 16)
  }

  private func attachmentCard(_ attachments: [MailboxAttachment]) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Label("Attachments", systemImage: "paperclip")
        .font(.headline)
      ForEach(attachments) { attachment in
        HStack(spacing: 10) {
          Image(systemName: "doc")
            .foregroundStyle(.secondary)
          VStack(alignment: .leading, spacing: 2) {
            Text(attachment.filename).lineLimit(1)
            HStack(spacing: 8) {
              if let contentType = attachment.contentType {
                Text(contentType)
              }
              if let size = attachment.size {
                Text(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file))
              }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
          }
          Spacer()
        }
        .padding(10)
        .background(
          .primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
      }
    }
    .padding(16)
    .mailboxGlassCard(radius: 16)
  }

  private func bodyCard(_ detail: MailboxMessageDetail) -> some View {
    Group {
      if detail.readableBody.isEmpty {
        ContentUnavailableView("No readable content", systemImage: "doc.text.magnifyingglass")
          .frame(maxWidth: .infinity, minHeight: 220)
      } else {
        Text(detail.readableBody)
          .font(.body)
          .lineSpacing(4)
          .textSelection(.enabled)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
    .padding(22)
    .mailboxGlassCard(tint: Color.white.opacity(0.015), radius: 20)
  }
}

private struct AddressLine: View {
  let title: LocalizedStringKey
  let addresses: [MailboxAddress]

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 12) {
      Text(title)
        .font(.caption.weight(.medium))
        .foregroundStyle(.secondary)
        .frame(width: 42, alignment: .trailing)
      Text(addresses.map(\.displayName).joined(separator: ", "))
        .textSelection(.enabled)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}
