# Screenshot Organizer

A macOS menubar app that automatically organizes screenshot files and screen recordings into year/month folders.

## Features

- Runs silently in the background as a menubar app
- Monitors a specified folder (default: Desktop) for new screenshot files and screen recordings
- Automatically moves screenshots to YYYY/MM folders based on the screenshot's date
- Automatically moves screen recordings to recordings/YYYY/MM folders
- Allows changing the monitored folder through the UI
- Organize files on-demand with "Organize now" option

## Requirements

- macOS 12.0 or later
- Xcode 13.0 or later (for building from source)

## Installation

### Download Pre-built Release

1. Download the latest release from the [Releases page](https://github.com/reorx/screenshot-organizer/releases)
2. Extract the .zip file and drag the app to your Applications folder
3. Launch the app

### Build from GitHub Actions

Each push to the main branch and every pull request automatically builds the app. You can download the latest build artifact from the [Actions page](https://github.com/reorx/screenshot-organizer/actions).

**For tagged releases**: When a version tag (e.g., `v1.2.1`) is pushed, the workflow automatically:
- Creates a properly named artifact (`ScreenshotOrganizer-v1.2.1.zip`)
- Creates a GitHub release with the artifact attached
- Generates release notes automatically

See [GitHub Actions documentation](docs/github-actions.md) for more details.

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
6. Use "Organize now" from the menu to organize files immediately

## How It Works

When you take a screenshot on macOS, it's saved with a filename in the format: `Screenshot YYYY-MM-DD at HH.MM.SS.png`. The app looks for files matching this pattern and moves them to a folder structure based on the date in the filename.

For example, a file named `Screenshot 2023-04-15 at 10.30.45.png` would be moved to `~/Desktop/2023/04/Screenshot 2023-04-15 at 10.30.45.png`.

Similarly, screen recordings with the format `Screen Recording YYYY-MM-DD at HH.MM.SS.mov` are organized into `~/Desktop/recordings/YYYY/MM/Screen Recording YYYY-MM-DD at HH.MM.SS.mov`.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
