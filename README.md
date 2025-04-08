# Screenshot Organizer

A macOS menubar app that automatically organizes screenshot files into year/month folders.

## Features

- Runs silently in the background as a menubar app
- Monitors a specified folder (default: Desktop) for new screenshot files
- Automatically moves screenshots to YYYY/MM folders based on the screenshot's date
- Allows changing the monitored folder through the UI

## Requirements

- macOS 12.0 or later
- Xcode 13.0 or later (for building from source)

## Installation

1. Download the latest release from the Releases page
2. Extract the .zip file and drag the app to your Applications folder
3. Launch the app

## Building from Source

1. Clone the repository
2. Open `ScreenshotOrganizer.xcodeproj` in Xcode
3. Build and run the app (⌘+R)

## Usage

1. Launch the app
2. The app runs in the background, with an icon in the menubar
3. Click the icon to access settings
4. By default, the app monitors your Desktop folder
5. You can change the monitored folder in the settings

## How It Works

When you take a screenshot on macOS, it's saved with a filename in the format: `Screenshot YYYY-MM-DD at HH.MM.SS.png`. The app looks for files matching this pattern and moves them to a folder structure based on the date in the filename.

For example, a file named `Screenshot 2023-04-15 at 10.30.45.png` would be moved to `~/Desktop/2023/04/Screenshot 2023-04-15 at 10.30.45.png`.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
