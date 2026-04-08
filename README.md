# WorldClockMenuBar

`WorldClockMenuBar` is a small macOS menu bar app that shows the current time in a selected timezone.

## Requirements

- macOS 13 or newer
- Xcode 16 or Apple Swift 6.2 command line tools

You can confirm Swift is installed with:

```bash
swift --version
```

## Build

Build the app from the project root with:

```bash
swift build
```

This creates the debug executable at:

```bash
.build/debug/WorldClockMenuBar
```

## Run

Run it directly through Swift Package Manager:

```bash
swift run WorldClockMenuBar
```

Or run the built executable after a successful build:

```bash
.build/debug/WorldClockMenuBar
```

When the app starts, it:

- adds a clock to the macOS menu bar
- opens the settings window so you can choose a timezone
- keeps running until you quit it from the menu bar app

If you launch it from a terminal, that terminal session stays attached until you quit the app.

## Open In Xcode

If you want to run or debug it in Xcode, open the Swift package:

```bash
open Package.swift
```

Then press Run in Xcode.
