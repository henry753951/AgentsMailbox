import SwiftUI

struct ContentView: View {
  @Bindable var model: MailboxViewModel
  @State private var searchTask: Task<Void, Never>?

  var body: some View {
    NavigationSplitView {
      MailboxSidebar(model: model)
        .navigationSplitViewColumnWidth(min: 190, ideal: 220, max: 280)
    } content: {
      MessageListView(model: model)
        .navigationSplitViewColumnWidth(min: 300, ideal: 350, max: 460)
    } detail: {
      MessageDetailView(model: model)
        .frame(minWidth: 440)
    }
    .navigationSplitViewStyle(.balanced)
    .searchable(text: $model.searchText, placement: .toolbar, prompt: Text("Search mail"))
    .toolbar {
      if #available(macOS 26.0, *) {
        ToolbarItem(placement: .primaryAction) {
          refreshButton
            .buttonStyle(.glass)
        }
        .sharedBackgroundVisibility(.hidden)

        ToolbarSpacer(.fixed, placement: .primaryAction)

        ToolbarItem(placement: .primaryAction) {
          settingsButton
            .buttonStyle(.glass)
        }
        .sharedBackgroundVisibility(.hidden)
      } else {
        ToolbarItem(placement: .primaryAction) {
          refreshButton
        }

        ToolbarItem(placement: .primaryAction) {
          settingsButton
        }
      }
    }
    .task { await model.start() }
    .onChange(of: model.searchText) {
      searchTask?.cancel()
      searchTask = Task {
        try? await Task.sleep(for: .milliseconds(350))
        guard !Task.isCancelled else { return }
        await model.refresh()
      }
    }
    .alert(
      "Mailbox Error",
      isPresented: Binding(
        get: { model.errorMessage != nil },
        set: { if !$0 { model.errorMessage = nil } }
      )
    ) {
      Button("OK", role: .cancel) { model.errorMessage = nil }
    } message: {
      Text(model.errorMessage ?? "")
    }
  }

  private var refreshButton: some View {
    Button {
      Task { await model.refresh() }
    } label: {
      Label("Refresh", systemImage: "arrow.clockwise")
    }
    .disabled(model.isLoading)
    .help("Refresh")
  }

  private var settingsButton: some View {
    SettingsLink {
      Label("Settings", systemImage: "gearshape")
    }
    .help("Settings")
  }
}
