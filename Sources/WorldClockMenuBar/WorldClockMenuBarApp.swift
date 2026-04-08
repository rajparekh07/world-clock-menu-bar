import AppKit
import Combine
import SwiftUI

@MainActor
@main
enum WorldClockMenuBarApp {
    private static let appDelegate = AppDelegate()

    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        app.delegate = appDelegate
        app.run()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let appState = AppState()
    private var cancellables = Set<AnyCancellable>()
    private var settingsWindowController: NSWindowController?
    private var statusItem: NSStatusItem?
    private var statusUpdateTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureStatusItem()
        startStatusUpdates()
        observeSelectionChanges()
        openSettingsWindow()
    }

    func applicationWillTerminate(_ notification: Notification) {
        statusUpdateTimer?.invalidate()
    }

    private func configureStatusItem() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let menu = NSMenu()
        menu.delegate = self

        statusItem.menu = menu

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "globe",
                accessibilityDescription: "World Clock"
            )
            button.imagePosition = .imageLeft
        }

        self.statusItem = statusItem
        refreshStatusItemTitle()
    }

    private func startStatusUpdates() {
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshStatusItemTitle()
            }
        }

        RunLoop.main.add(timer, forMode: .common)
        statusUpdateTimer = timer
    }

    private func observeSelectionChanges() {
        appState.$selectedTimeZoneIdentifier
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshStatusItemTitle()
            }
            .store(in: &cancellables)

        appState.$showsSeconds
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshStatusItemTitle()
            }
            .store(in: &cancellables)
    }

    private func refreshStatusItemTitle() {
        guard let button = statusItem?.button else {
            return
        }

        let date = Date()
        let title = appState.menuBarClockText(for: date)
        let font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .medium)

        button.attributedTitle = NSAttributedString(
            string: title,
            attributes: [.font: font]
        )

        if let city = appState.selectedOption?.cityName {
            button.toolTip = "\(city) • \(appState.timeZoneSummaryText(for: date))"
        } else {
            button.toolTip = appState.timeZoneSummaryText(for: date)
        }
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        let now = Date()
        let city = appState.selectedOption?.cityName ?? "World Clock"

        addDisabledMenuItem(city, to: menu)
        addDisabledMenuItem(appState.fullTimeText(for: now), to: menu)
        addDisabledMenuItem(appState.dateText(for: now), to: menu)
        addDisabledMenuItem(appState.timeZoneSummaryText(for: now), to: menu)

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(
            title: "Choose Timezone…",
            action: #selector(openSettingsWindowFromMenu),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
    }

    private func addDisabledMenuItem(_ title: String, to menu: NSMenu) {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        menu.addItem(item)
    }

    @objc
    private func openSettingsWindowFromMenu() {
        openSettingsWindow()
    }

    @objc
    private func quitApp() {
        NSApp.terminate(nil)
    }

    private func openSettingsWindow() {
        if settingsWindowController == nil {
            let contentView = SettingsView(appState: appState)
            let hostingController = NSHostingController(rootView: contentView)
            let window = NSWindow(contentViewController: hostingController)

            window.title = "World Clock Settings"
            window.setContentSize(NSSize(width: 560, height: 680))
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            window.center()
            window.isReleasedWhenClosed = false
            window.collectionBehavior = [.fullScreenPrimary]

            settingsWindowController = NSWindowController(window: window)
        }

        settingsWindowController?.showWindow(nil)
        settingsWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
