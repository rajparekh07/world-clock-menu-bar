import Foundation

struct TimeZoneOption: Identifiable, Hashable {
    let id: String
    let cityName: String
    let identifier: String
    let localizedName: String?
    let offsetText: String
    let sortOffset: Int

    func matches(_ query: String) -> Bool {
        let normalizedQuery = query.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .autoupdatingCurrent)

        let haystack = [
            cityName,
            identifier,
            localizedName,
            offsetText,
        ]
        .compactMap { $0 }
        .joined(separator: " ")
        .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .autoupdatingCurrent)

        return haystack.contains(normalizedQuery)
    }
}

enum TimeZoneCatalog {
    static func options(excluding localIdentifier: String, at date: Date = .now) -> [TimeZoneOption] {
        TimeZone.knownTimeZoneIdentifiers
            .filter { $0 != localIdentifier }
            .compactMap { option(for: $0, at: date) }
            .sorted { lhs, rhs in
                if lhs.sortOffset != rhs.sortOffset {
                    return lhs.sortOffset < rhs.sortOffset
                }

                if lhs.cityName != rhs.cityName {
                    return lhs.cityName.localizedStandardCompare(rhs.cityName) == .orderedAscending
                }

                return lhs.identifier.localizedStandardCompare(rhs.identifier) == .orderedAscending
            }
    }

    static func option(for identifier: String, at date: Date = .now) -> TimeZoneOption? {
        guard let timeZone = TimeZone(identifier: identifier) else {
            return nil
        }

        return TimeZoneOption(
            id: identifier,
            cityName: cityName(for: identifier),
            identifier: identifier,
            localizedName: localizedName(for: timeZone),
            offsetText: offsetText(for: timeZone, at: date),
            sortOffset: timeZone.secondsFromGMT(for: date)
        )
    }

    static func normalizedSelection(_ proposedIdentifier: String?, excluding localIdentifier: String) -> String {
        guard
            let proposedIdentifier,
            proposedIdentifier != localIdentifier,
            TimeZone(identifier: proposedIdentifier) != nil
        else {
            return defaultIdentifier(excluding: localIdentifier)
        }

        return proposedIdentifier
    }

    static func offsetText(for timeZone: TimeZone, at date: Date = .now) -> String {
        let totalSeconds = timeZone.secondsFromGMT(for: date)
        let sign = totalSeconds >= 0 ? "+" : "-"
        let absoluteSeconds = abs(totalSeconds)
        let hours = absoluteSeconds / 3600
        let minutes = (absoluteSeconds % 3600) / 60
        return "GMT\(sign)\(hours):" + String(format: "%02d", minutes)
    }

    private static func defaultIdentifier(excluding localIdentifier: String) -> String {
        let preferredIdentifiers = [
            "Etc/UTC",
            "Europe/London",
            "America/New_York",
            "Asia/Tokyo",
            "Australia/Sydney",
        ]

        if let preferred = preferredIdentifiers.first(where: { identifier in
            identifier != localIdentifier && TimeZone(identifier: identifier) != nil
        }) {
            return preferred
        }

        return TimeZone.knownTimeZoneIdentifiers.first(where: { $0 != localIdentifier }) ?? "Etc/UTC"
    }

    private static func cityName(for identifier: String) -> String {
        if ["Etc/UTC", "UTC", "GMT"].contains(identifier) {
            return "UTC"
        }

        let components = identifier
            .split(separator: "/")
            .map { String($0).replacingOccurrences(of: "_", with: " ") }

        guard let last = components.last else {
            return identifier.replacingOccurrences(of: "_", with: " ")
        }

        if components.count > 2 {
            return components.suffix(2).joined(separator: " / ")
        }

        return last
    }

    private static func localizedName(for timeZone: TimeZone) -> String? {
        timeZone.localizedName(for: .generic, locale: .autoupdatingCurrent)
    }
}
