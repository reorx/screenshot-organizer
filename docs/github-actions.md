# GitHub Actions Workflow Documentation

## Build and Package App Workflow

This workflow automatically builds the ScreenshotOrganizer app and creates artifacts based on the type of commit.

### Triggers

- **Push to branches**: `master`, `develop`
- **Push to tags**: Starting with `v*` (e.g., `v1.2.1`, `v2.0.0`)
- **Pull requests**: To `master` branch
- **Manual trigger**: Via `workflow_dispatch`

### Artifact Naming

The workflow creates different artifact names based on the commit type:

#### For Tagged Commits
- **Artifact name**: `ScreenshotOrganizer-{tag}` (e.g., `ScreenshotOrganizer-v1.2.1`)
- **Zip file**: `ScreenshotOrganizer-{tag}.zip` (e.g., `ScreenshotOrganizer-v1.2.1.zip`)
- **Contains**: `ScreenshotOrganizer.app` directly (no double-zip)

#### For Regular Commits
- **Artifact name**: `ScreenshotOrganizer-{sha}` (e.g., `ScreenshotOrganizer-abc123def456`)
- **Zip file**: `ScreenshotOrganizer.zip`
- **Contains**: `ScreenshotOrganizer.app` directly (no double-zip)

### Automatic Release Creation

When a tag starting with `v*` is pushed:

1. **Build Process**: App is built and packaged automatically
2. **Artifact Creation**: Creates `ScreenshotOrganizer-{tag}.zip`
3. **Release Creation**: Automatically creates a GitHub release with:
   - **Name**: `Release {tag}` (e.g., `Release v1.2.1`)
   - **Attached file**: The zip artifact
   - **Release notes**: Auto-generated from commits
   - **Status**: Published (not draft, not prerelease)

### Usage Examples

#### Creating a Release
```bash
# Tag the current commit
git tag v1.2.1
git push origin v1.2.1

# This will:
# 1. Trigger the workflow
# 2. Build the app
# 3. Create artifact: ScreenshotOrganizer-v1.2.1
# 4. Create release: "Release v1.2.1"
# 5. Attach ScreenshotOrganizer-v1.2.1.zip to the release
```

#### Development Builds
```bash
# Push to master or develop
git push origin master

# This will:
# 1. Trigger the workflow
# 2. Build the app
# 3. Create artifact: ScreenshotOrganizer-{sha}
# 4. No release created
```

### Key Improvements

1. **Professional Naming**: Tagged releases use semantic version names instead of SHA hashes
2. **Single Zip**: Eliminated confusing double-zip structure
3. **Automatic Releases**: No manual intervention needed for releases
4. **Consistent Artifacts**: Clear naming convention for all build types