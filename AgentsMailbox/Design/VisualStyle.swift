import SwiftUI

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
