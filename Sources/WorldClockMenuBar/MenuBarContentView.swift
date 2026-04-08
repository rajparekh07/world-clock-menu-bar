import AppKit
import SwiftUI

struct MenuBarLabel: View {
    @ObservedObject var appState: AppState

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            Label(appState.menuBarClockText(for: context.date), systemImage: "globe")
                .labelStyle(.titleAndIcon)
                .monospacedDigit()
        }
    }
}

struct MenuBarContentView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            Divider()

            TimelineView(.periodic(from: .now, by: 1)) { context in
                VStack(alignment: .leading, spacing: 10) {
                    Text(appState.fullTimeText(for: context.date))
                        .font(.system(size: 30, weight: .semibold, design: .rounded))
                        .monospacedDigit()

                    Text(appState.dateText(for: context.date))
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Text(appState.timeZoneSummaryText(for: context.date))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Divider()

            VStack(spacing: 10) {
                Button {
                    openSettingsWindow()
                } label: {
                    Label("Choose Timezone", systemImage: "gearshape")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    NSApp.terminate(nil)
                } label: {
                    Label("Quit", systemImage: "power")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(16)
        .frame(width: 340)
    }

    @ViewBuilder
    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(appState.selectedOption?.cityName ?? "World Clock")
                    .font(.title3.weight(.semibold))

                Text(appState.selectedOption?.identifier ?? appState.selectedTimeZoneIdentifier)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "globe.europe.africa.fill")
                .font(.system(size: 30))
                .foregroundStyle(.tint)
        }
    }

    private func openSettingsWindow() {
        let handled = NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)

        if !handled {
            _ = NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }

        NSApp.activate(ignoringOtherApps: true)
    }
}
