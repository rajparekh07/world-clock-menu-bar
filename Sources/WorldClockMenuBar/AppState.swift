import Combine
import Foundation

@MainActor
final class AppState: ObservableObject {
    private static let selectedTimeZoneKey = "selectedTimeZoneIdentifier"
    private static let showsSecondsKey = "showsSeconds"

    private let defaults: UserDefaults
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var availableTimeZones: [TimeZoneOption] = []
    @Published private(set) var localTimeZoneIdentifier: String
    @Published private(set) var selectedTimeZoneIdentifier: String
    @Published private(set) var showsSeconds: Bool

    init(defaults: UserDefaults = .standard) {
        let localIdentifier = TimeZone.autoupdatingCurrent.identifier

        self.defaults = defaults
        self.localTimeZoneIdentifier = localIdentifier
        self.selectedTimeZoneIdentifier = TimeZoneCatalog.normalizedSelection(
            defaults.string(forKey: Self.selectedTimeZoneKey),
            excluding: localIdentifier
        )
        self.showsSeconds = defaults.object(forKey: Self.showsSecondsKey) as? Bool ?? true

        rebuildAvailableTimeZones()
        normalizeSelectedTimeZoneIfNeeded()

        NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.handleSystemTimeZoneChange()
            }
            .store(in: &cancellables)
    }

    var selectedTimeZone: TimeZone {
        TimeZone(identifier: selectedTimeZoneIdentifier) ?? .gmt
    }

    var selectedOption: TimeZoneOption? {
        availableTimeZones.first(where: { $0.id == selectedTimeZoneIdentifier })
            ?? TimeZoneCatalog.option(for: selectedTimeZoneIdentifier)
    }

    func selectTimeZone(_ identifier: String) {
        let normalized = TimeZoneCatalog.normalizedSelection(
            identifier,
            excluding: localTimeZoneIdentifier
        )

        guard normalized != selectedTimeZoneIdentifier else {
            return
        }

        selectedTimeZoneIdentifier = normalized
        defaults.set(normalized, forKey: Self.selectedTimeZoneKey)
    }

    func menuBarClockText(for date: Date) -> String {
        format(date, with: .menuBarTime, timeZone: selectedTimeZone)
    }

    func fullTimeText(for date: Date) -> String {
        format(date, with: .detailTime, timeZone: selectedTimeZone)
    }

    func dateText(for date: Date) -> String {
        format(date, with: .detailDate, timeZone: selectedTimeZone)
    }

    func timeZoneSummaryText(for date: Date) -> String {
        let abbreviation = selectedTimeZone.abbreviation(for: date)
        let offset = TimeZoneCatalog.offsetText(for: selectedTimeZone, at: date)
        return [selectedTimeZone.identifier, abbreviation, offset]
            .compactMap { value in
                guard let value, !value.isEmpty else {
                    return nil
                }
                return value
            }
            .joined(separator: " • ")
    }

    func setShowsSeconds(_ newValue: Bool) {
        guard newValue != showsSeconds else {
            return
        }

        showsSeconds = newValue
        defaults.set(newValue, forKey: Self.showsSecondsKey)
    }

    private func rebuildAvailableTimeZones(date: Date = .now) {
        availableTimeZones = TimeZoneCatalog.options(
            excluding: localTimeZoneIdentifier,
            at: date
        )
    }

    private func normalizeSelectedTimeZoneIfNeeded() {
        let normalized = TimeZoneCatalog.normalizedSelection(
            selectedTimeZoneIdentifier,
            excluding: localTimeZoneIdentifier
        )

        if normalized != selectedTimeZoneIdentifier {
            selectedTimeZoneIdentifier = normalized
        }

        defaults.set(normalized, forKey: Self.selectedTimeZoneKey)
    }

    private func handleSystemTimeZoneChange() {
        localTimeZoneIdentifier = TimeZone.autoupdatingCurrent.identifier
        rebuildAvailableTimeZones()
        normalizeSelectedTimeZoneIfNeeded()
    }

    private func format(_ date: Date, with style: DateDisplayStyle, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.timeZone = timeZone

        switch style {
        case .menuBarTime:
            formatter.setLocalizedDateFormatFromTemplate(showsSeconds ? "jmss" : "jm")
        case .detailTime:
            formatter.setLocalizedDateFormatFromTemplate(showsSeconds ? "jmss" : "jm")
        case .detailDate:
            formatter.setLocalizedDateFormatFromTemplate("EEEE, MMM d")
        }

        return formatter.string(from: date)
    }
}

private enum DateDisplayStyle {
    case menuBarTime
    case detailTime
    case detailDate
}
