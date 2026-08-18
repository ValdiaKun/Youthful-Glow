# Youthful — Windows / Sideloadly Build

This package is prepared for a **no-Mac** workflow:

Windows PC → GitHub Actions macOS runner → unsigned IPA → Sideloadly → iPhone

## Important

The GitHub workflow builds the iOS app without signing it. Sideloadly will sign the IPA with your Apple ID when you install it.

This means you do **not** need to buy a Mac. A free Apple ID can be used with Sideloadly, but free provisioning normally expires after 7 days and must be refreshed. Sideloadly documents automatic refreshing when your iPhone and PC can reconnect by USB/Wi-Fi.

You do not need to give your Apple ID password to this project or to GitHub. Enter it only in Sideloadly when prompted.

## 1. Create a GitHub repository

1. On Windows, open GitHub in your browser and create a new repository named `Youthful`.
2. Make it **Private** if you prefer.
3. Do not add a README/license/gitignore during creation.

## 2. Upload this project

Upload the contents of this folder to the repository so that these are at the repository root:

- `Youthful.xcodeproj/`
- `Youthful/`
- `.github/`

The `.github/workflows/build-ipa.yml` file is what builds the IPA.

## 3. Run the build

On GitHub:

1. Open the repository.
2. Click **Actions**.
3. Select **Build Youthful IPA**.
4. Click **Run workflow**.
5. Wait for the macOS build to finish.
6. Open the completed workflow run.
7. Under **Artifacts**, download `Youthful-unsigned-ipa`.

Unzip it on Windows. You will get `Youthful.ipa`.

## 4. Install with Sideloadly

1. Install Apple's **web versions** of iTunes and iCloud if Sideloadly asks for them. Sideloadly specifically says its Windows setup requires the web versions rather than the Microsoft Store versions.
2. Connect your iPhone to Windows with USB.
3. Unlock the iPhone and tap **Trust** if prompted.
4. Open Sideloadly.
5. Select your iPhone.
6. Drag `Youthful.ipa` into the IPA box.
7. Enter your Apple ID.
8. Click **Start**.
9. Enter your Apple ID password when Sideloadly asks.
10. Wait for installation.
11. On the iPhone, if required, go to **Settings → General → VPN & Device Management** and trust the developer profile.
12. Open Youthful.

For a free Apple ID, Sideloadly says the app is normally valid for 7 days. Its automatic refresh feature can re-sign it when the phone and PC are available.

## 5. Wi-Fi refresh

After the first successful USB installation, Sideloadly documents Wi-Fi sideloading on Windows:

- Connect the iPhone and Windows PC to the same Wi-Fi.
- In Apple's iTunes, open the iPhone and enable **Sync with this iPhone over Wi-Fi**.
- Sync once.
- Keep Sideloadly's refresh feature enabled.

## Security

Use a GitHub **Private** repository if you don't want the source visible publicly.

Do not commit Apple passwords, private certificates, `.p8` keys, or provisioning profiles into the repository.

## App details

- Name: Youthful
- Bundle ID: `com.example.Youthful`
- Minimum iOS: 17.0
- Version: 1.0
- Premium UI + routine tracking + progress photos + product tracker + reminders
