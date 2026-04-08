import SwiftUI

struct SettingsView: View {
    @ObservedObject var appState: AppState

    @State private var searchText = ""

    private var showsSecondsBinding: Binding<Bool> {
        Binding(
            get: { appState.showsSeconds },
            set: { appState.setShowsSeconds($0) }
        )
    }

    private var filteredTimeZones: [TimeZoneOption] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else {
            return appState.availableTimeZones
        }

        return appState.availableTimeZones.filter { $0.matches(query) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            selectedTimeZoneCard

            VStack(alignment: .leading, spacing: 10) {
                Text("Choose a timezone")
                    .font(.headline)

                Toggle("Show seconds", isOn: showsSecondsBinding)

                TextField("Search city or timezone", text: $searchText)
                    .textFieldStyle(.roundedBorder)

                List(filteredTimeZones) { option in
                    Button {
                        appState.selectTimeZone(option.id)
                    } label: {
                        TimeZoneRow(
                            option: option,
                            isSelected: option.id == appState.selectedTimeZoneIdentifier
                        )
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.inset)

                if filteredTimeZones.isEmpty {
                    Text("No timezone matches your search.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(20)
        .frame(minWidth: 520, minHeight: 620)
    }

    @ViewBuilder
    private var selectedTimeZoneCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Selected timezone")
                .font(.headline)

            if let option = appState.selectedOption {
                Text(option.cityName)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))

                TimelineView(.periodic(from: .now, by: 1)) { context in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(appState.fullTimeText(for: context.date))
                            .font(.system(size: 42, weight: .bold, design: .rounded))
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
            } else {
                Text("Pick any timezone except your local one.")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct TimeZoneRow: View {
    let option: TimeZoneOption
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(option.cityName)
                    .font(.headline)

                Text(rowSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.tint)
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 4)
    }

    private var rowSubtitle: String {
        var details = [option.identifier]

        if let localizedName = option.localizedName, !localizedName.isEmpty {
            details.append(localizedName)
        }

        details.append(option.offsetText)

        return details.joined(separator: " • ")
    }
}
