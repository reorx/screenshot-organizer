## Invalid Display Identifier Logs

When running the app for a long time, these logs appear frequently in the Xcode console:
```
invalid display identifier A00595AB-E552-4F31-B0F4-A07E3F70E8B2
invalid display identifier 6CED9FBD-C3DB-4309-9DFB-D83D9EE5BD3A
```

### Cause
These UUIDs are display identifiers that macOS uses to identify screens. The logs appear because:

1. macOS assigns a unique identifier to each display in the system
2. When screenshots are taken, macOS associates them with the display they were captured from
3. When the app runs for a long time, displays that were previously connected (external monitors, etc.) are no longer available
4. When macOS tries to reference these display IDs, it logs "invalid display identifier" because those displays are no longer connected

### Impact
- These logs are harmless and don't indicate a problem with the app
- They come from the macOS system, not the application code
- They can be safely ignored as they don't affect functionality

### Workaround
To prevent these logs from cluttering the console, add a filter for "invalid display identifier" in Xcode's console filter box.
