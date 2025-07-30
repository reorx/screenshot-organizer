# Code Signing and Notarization Setup

This document explains how to set up code signing and notarization for the ScreenshotOrganizer macOS app to resolve Gatekeeper security warnings.

## Problem

When downloading the app built by GitHub Actions, macOS shows the error:
```
"ScreenshotOrganizer" is damaged and can't be opened. You should move it to the Trash.
```

This happens because the app is not code signed with a valid Developer ID certificate, causing Gatekeeper to block it.

## Solution

The GitHub Actions workflow now supports automatic code signing and notarization when the proper certificates and credentials are configured as repository secrets.

## Requirements

1. **Apple Developer Account** - You need a paid Apple Developer Program membership ($99/year)
2. **Developer ID Application Certificate** - For signing apps distributed outside the Mac App Store
3. **App-Specific Password** - For notarization

## Setup Instructions

### 1. Create Developer ID Certificate

1. Go to [Apple Developer Portal](https://developer.apple.com/account/resources/certificates/list)
2. Click "+" to create a new certificate
3. Choose "Developer ID Application" under "Software"
4. Follow the instructions to create a Certificate Signing Request (CSR)
5. Download the certificate (.cer file)

### 2. Export Certificate as P12

1. Double-click the downloaded certificate to add it to Keychain Access
2. In Keychain Access, find the certificate under "My Certificates"
3. Right-click and select "Export..."
4. Choose "Personal Information Exchange (.p12)" format
5. Set a strong password for the P12 file
6. Save the file securely

### 3. Create App-Specific Password

1. Go to [Apple ID account page](https://appleid.apple.com/account/manage)
2. Sign in with your Apple Developer account
3. In the "Security" section, click "Generate Password" under "App-Specific Passwords"
4. Enter a label like "ScreenshotOrganizer Notarization"
5. Save the generated password securely

### 4. Configure GitHub Secrets

Add the following secrets to your GitHub repository:

1. **`DEVELOPER_ID_APPLICATION_CERT_P12_BASE64`**
   ```bash
   # Convert P12 to base64
   base64 -i /path/to/your/certificate.p12 | pbcopy
   ```
   Paste the base64-encoded content as the secret value.

2. **`DEVELOPER_ID_APPLICATION_CERT_PASSWORD`**
   The password you set when exporting the P12 file.

3. **`KEYCHAIN_PASSWORD`**
   A strong password for the temporary keychain (can be any secure password).

4. **`APPLE_ID`**
   Your Apple ID email address (the one associated with your Developer account).

5. **`APPLE_APP_SPECIFIC_PASSWORD`**
   The app-specific password generated in step 3.

6. **`APPLE_TEAM_ID`**
   Your 10-character Team ID from [Apple Developer Portal](https://developer.apple.com/account/#/membership/).

### 5. Adding Secrets to GitHub

1. Go to your repository on GitHub
2. Click "Settings" → "Secrets and variables" → "Actions"
3. Click "New repository secret"
4. Add each secret with the exact names listed above

## How It Works

When all secrets are configured:

1. **Code Signing**: The workflow imports your Developer ID certificate and signs the app with hardened runtime enabled
2. **Notarization**: The signed app is submitted to Apple for notarization
3. **Stapling**: The notarization ticket is stapled to the app
4. **Verification**: The workflow verifies the app passes Gatekeeper checks

If secrets are not configured, the workflow falls back to building an unsigned app (current behavior).

## Verification

After successful code signing and notarization, users can:

1. Download and run the app without Gatekeeper warnings
2. Verify the signature with:
   ```bash
   codesign --verify --verbose=2 /path/to/ScreenshotOrganizer.app
   spctl --assess --verbose=2 --type exec /path/to/ScreenshotOrganizer.app
   ```

## Troubleshooting

### Certificate Issues
- Ensure the certificate is "Developer ID Application" type, not "Mac App Store" 
- Verify the certificate hasn't expired
- Check that the P12 export includes the private key

### Notarization Issues
- Verify the Apple ID has Developer Program access
- Ensure the app-specific password is correct and hasn't expired
- Check that the Team ID matches your developer account

### GitHub Actions Issues
- Verify all secret names are exactly as specified (case-sensitive)
- Check the workflow logs for specific error messages
- Ensure base64 encoding of the P12 file is correct (no line breaks)

## Security Notes

- P12 files contain private keys - keep them secure and never commit to source control
- App-specific passwords are safer than using your main Apple ID password
- Repository secrets are encrypted and only visible to repository admins
- The temporary keychain is automatically cleaned up after the build

## Manual Workaround (Temporary)

If you can't set up code signing immediately, users can manually remove the quarantine attribute:

```bash
xattr -d com.apple.quarantine /path/to/ScreenshotOrganizer.app
```

However, this requires technical knowledge and reduces security, so proper code signing is strongly recommended.