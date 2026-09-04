import SwiftUI

@main
struct AgentsMailboxApp: App {
  @State private var model = MailboxViewModel()
  @State private var updater = AppUpdater()

  private var verificationColorScheme: ColorScheme? {
    if CommandLine.arguments.contains("--force-light") { return .light }
    if CommandLine.arguments.contains("--force-dark") { return .dark }
    return nil
  }

  var body: some Scene {
    WindowGroup {
      ContentView(model: model)
        .frame(minWidth: 980, minHeight: 620)
        .preferredColorScheme(verificationColorScheme)
    }
    .defaultSize(width: 1280, height: 800)

    Settings {
      SettingsView(model: model)
    }
    .commands {
      CommandGroup(after: .appInfo) {
        Button("Check for Updates…") {
          updater.checkForUpdates()
        }
      }
    }
  }
}
