import AppKit
import SwiftUI

@main
struct SNMPMonitorApp: App {
    @StateObject private var store = MonitorStore()

    init() {
        DispatchQueue.main.async {
            NSApplication.shared.setActivationPolicy(.regular)
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 1100, minHeight: 760)
        }
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Rafraichir") {
                    store.refreshOnce()
                }
                .keyboardShortcut("r", modifiers: [.command])
            }
        }
    }
}
