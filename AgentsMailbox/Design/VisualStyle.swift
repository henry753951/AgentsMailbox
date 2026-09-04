import SwiftUI

enum MailboxPalette {
  static let blue = Color(red: 0.12, green: 0.48, blue: 1.00)
  static let cyan = Color(red: 0.20, green: 0.78, blue: 0.95)
  static let violet = Color(red: 0.53, green: 0.36, blue: 0.98)
}

struct MailboxBackground: View {
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    ZStack {
      Color(nsColor: .windowBackgroundColor)
      RadialGradient(
        colors: [MailboxPalette.blue.opacity(colorScheme == .dark ? 0.18 : 0.12), .clear],
        center: .topLeading,
        startRadius: 20,
        endRadius: 620
      )
      RadialGradient(
        colors: [MailboxPalette.violet.opacity(colorScheme == .dark ? 0.13 : 0.09), .clear],
        center: .bottomTrailing,
        startRadius: 10,
        endRadius: 700
      )
    }
    .ignoresSafeArea()
  }
}

private struct AdaptiveGlassCard: ViewModifier {
  let tint: Color?
  let radius: CGFloat

  func body(content: Content) -> some View {
    if #available(macOS 26.0, *) {
      content.glassEffect(
        .regular.tint(tint), in: RoundedRectangle(cornerRadius: radius, style: .continuous))
    } else {
      content
        .background(
          .regularMaterial, in: RoundedRectangle(cornerRadius: radius, style: .continuous)
        )
        .overlay {
          RoundedRectangle(cornerRadius: radius, style: .continuous)
            .strokeBorder(.primary.opacity(0.08))
        }
    }
  }
}

extension View {
  func mailboxGlassCard(tint: Color? = nil, radius: CGFloat = 18) -> some View {
    modifier(AdaptiveGlassCard(tint: tint, radius: radius))
  }

  @ViewBuilder
  func mailboxGlassButton(prominent: Bool = false) -> some View {
    if #available(macOS 26.0, *) {
      if prominent {
        buttonStyle(.glassProminent)
      } else {
        buttonStyle(.glass)
      }
    } else if prominent {
      buttonStyle(.borderedProminent)
    } else {
      buttonStyle(.bordered)
    }
  }
}

struct MailboxMark: View {
  var size: CGFloat = 42

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
        .fill(
          LinearGradient(
            colors: [MailboxPalette.blue, MailboxPalette.violet],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
      Image(systemName: "envelope.fill")
        .font(.system(size: size * 0.42, weight: .semibold))
        .foregroundStyle(.white)
    }
    .frame(width: size, height: size)
    .shadow(color: MailboxPalette.blue.opacity(0.2), radius: size * 0.2, y: size * 0.08)
    .accessibilityHidden(true)
  }
}

struct CircularToolbarButtonStyle: ViewModifier {
  func body(content: Content) -> some View {
    content
      .labelStyle(.iconOnly)
      .controlSize(.large)
      .frame(width: 34, height: 34)
      .mailboxGlassButton()
  }
}
