# Firebase App Distribution setup

How the `production` branch gets turned into a signed release APK on
testers' phones via GitHub Actions + Firebase App Distribution, and how to
reproduce or extend this setup.

## Overview

```
push to `production` branch
        │
        ▼
GitHub Actions (.github/workflows/deploy-production.yml)
        │
        ├─ decode release keystore from secrets
        ├─ flutter build apk --release --target-platform android-arm64
        │
        ▼
Firebase App Distribution (project: contact-list-ddf05, app: com.israa050.moneylog)
        │
        ▼
"internal" tester group gets a notification + install link
```

Two things are intentionally decoupled: signing (Android's own release-key
mechanism) and distribution (Firebase). CI needs credentials for both, held
as GitHub Actions repo secrets — nothing sensitive is ever committed.

## Part 1 — Android release signing

### 1.1 Generate a release keystore

Run this **locally, in your own terminal** — it prompts for passwords
interactively, so it shouldn't be run through an AI agent or shared shell:

```bash
keytool -genkey -v -keystore money-log-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias moneylog
```

- `-validity 10000` (≈27 years) — Android requires the signing cert to
  outlive the app.
- Save the resulting `.jks` file **and both passwords** in a password
  manager immediately. There is no recovery path if lost — losing them
  means you can never publish an update signed as the same app again.

Reference: [Android docs — Sign your app](https://developer.android.com/studio/publish/app-signing)

### 1.2 Where the file lives locally

```
android/app/money-log-release.jks   # the keystore itself
android/key.properties              # passwords + alias, read by Gradle
```

Both are gitignored (`*.jks`, `*.keystore`, `key.properties` — see
`.gitignore`; Flutter's own `android/.gitignore` also covers `*.jks`).
`key.properties` shape:

```properties
storePassword=<keystore password>
keyPassword=<key password>
keyAlias=moneylog
storeFile=money-log-release.jks
```

### 1.3 Gradle wiring

`android/app/build.gradle.kts` loads `key.properties` if present and signs
release builds with it; falls back to **debug** signing if the file is
absent, so a contributor's checkout (which won't have the keystore) still
builds:

```kotlin
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}
// ... signingConfigs { create("release") { storeFile = file(...); ... } }
// ... buildTypes { release { signingConfig = if (exists) release else debug } }
```

### 1.4 Verifying a build is actually signed with your key

```bash
"$ANDROID_HOME/build-tools/<version>/apksigner" verify --print-certs build/app/outputs/flutter-apk/app-release.apk
```

Expect `Signer #1 certificate DN: CN=<your name>, ...` — **not**
`CN=Android Debug, O=Android`, which would mean it silently fell back to
debug signing (e.g. because `key.properties` wasn't found).

## Part 2 — App size (why an unmodified release build is huge)

`flutter build apk --release` with no flags builds a **fat APK** containing
native engine binaries (`libflutter.so`, `libapp.so`, `libsqlite3.so`) for
**three** CPU architectures at once (`x86_64`, `arm64-v8a`, `armeabi-v7a`),
even though a single device only ever uses one. For this app that was the
difference between ~52.6MB and ~21.7MB.

Fix: build only for the architecture that matters. Nearly all real Android
phones today are `arm64-v8a`:

```bash
flutter build apk --release --target-platform android-arm64
```

The alternative — `flutter build appbundle` (`.aab`) — lets Google
Play/Firebase split per-device automatically, but testers then install via
Firebase's tester flow rather than a plain sideloaded APK. We chose the
single-arm64-APK approach for simplicity.

Reference: [Flutter docs — Build and release an Android app](https://docs.flutter.dev/deployment/android)

## Part 3 — Firebase project + App Distribution

### 3.1 Firebase CLI

```bash
npm install -g firebase-tools
firebase --version
firebase login
```

**Known error:** a previously-broken global install can fail with
`ENOENT ... firebase-tools/lib/templates/hosting/init.js` on any command.
Fix: `npm install -g firebase-tools` again (clean reinstall).

**Known gotcha:** `firebase login` (no flags) opens a local browser and
listens on localhost for the redirect — this hangs indefinitely in a
headless/remote shell. Use `firebase login --no-localhost` instead, which
prints a URL to open manually and a `firebase login <code>` command to
paste the resulting authorization code into.

Reference: [Firebase CLI reference](https://firebase.google.com/docs/cli)

### 3.2 Link the repo to an existing project

```bash
firebase projects:list
```

`firebase use --add <project-id>` requires the directory to already be
recognized as a Firebase project directory. `firebase init` is fully
interactive (feature/project selection prompts) and **hangs in a
non-interactive shell** — if that happens, stop the process and instead
write the two config files directly:

`.firebaserc`:
```json
{ "projects": { "default": "<project-id>" } }
```

`firebase.json`:
```json
{}
```

Then `firebase use` will resolve correctly with no prompts.

### 3.3 Registering the Android app

**Known gotcha:** an existing Firebase project may already have an Android
app registered under an unrelated package name (e.g. left over from a
different prototype). Check before reusing one:

```bash
firebase apps:list --project <project-id>
firebase apps:sdkconfig ANDROID <app-id> --project <project-id>
```

Look at `client[0].client_info.android_client_info.package_name` in the
output — if it doesn't match this app's `applicationId`
(`com.israa050.moneylog`), register a new app instead of reusing it:

```bash
firebase apps:create ANDROID "Money Log" --package-name com.israa050.moneylog --project <project-id>
```

Note the **App ID** it prints (`1:...:android:...`) — this becomes the
`FIREBASE_APP_ID` secret.

### 3.4 Enabling App Distribution

This is a **one-time console step** — the CLI/API can't turn the product on
for the first time on a project. Symptom if skipped:
`firebase appdistribution:group:list` fails with `Failed to list groups.`

Fix: [Firebase Console](https://console.firebase.google.com) → select the
project → **Release & Monitor → App Distribution** → **Get started**.
After that, the CLI group commands work.

### 3.5 Tester group

```bash
firebase appdistribution:group:create "Internal Testers" internal --project <project-id>
firebase appdistribution:testers:list --project <project-id>
```

Add testers either via the console (**App Distribution → Testers &
Groups**) or the CLI — check `firebase appdistribution:testers:add --help`
for current flag names, they've changed across CLI versions.

Reference: [Firebase App Distribution docs](https://firebase.google.com/docs/app-distribution)

### 3.6 CI service account

The CLI has no command to create IAM service accounts; this is a console
(or `gcloud`) step. Via console:

1. [console.cloud.google.com/iam-admin/serviceaccounts](https://console.cloud.google.com/iam-admin/serviceaccounts)
   → select the same project → **Create Service Account**.
2. Grant role **Firebase App Distribution Admin** — this is a
   project-level role grant, unrelated to any specific registered app; you
   won't see the Android app anywhere in this flow, that's expected.
3. **Keys** tab → **Add Key** → **Create new key** → **JSON**. Downloads
   once; there's no way to re-download the same key later (generate a new
   one if lost).

Reference: [IAM service accounts](https://cloud.google.com/iam/docs/service-accounts-create)

## Part 4 — Wiring secrets into GitHub Actions

All CI credentials live as encrypted repo secrets
(Settings → Secrets and variables → Actions), never committed:

| Secret | Source |
|---|---|
| `FIREBASE_APP_ID` | Output of `firebase apps:create`/`apps:list` |
| `FIREBASE_SERVICE_ACCOUNT` | Contents of the service account JSON (§3.6) |
| `KEYSTORE_BASE64` | `base64 -w 0 android/app/money-log-release.jks` |
| `KEYSTORE_PASSWORD` | From `key.properties` (`storePassword`) |
| `KEY_ALIAS` | From `key.properties` (`keyAlias`) |
| `KEY_PASSWORD` | From `key.properties` (`keyPassword`) |

Setting them via `gh` CLI, straight from disk, so nothing touches shell
history or an AI/chat transcript:

```bash
base64 -w 0 android/app/money-log-release.jks | gh secret set KEYSTORE_BASE64
gh secret set FIREBASE_SERVICE_ACCOUNT < service-account.json
gh secret set FIREBASE_APP_ID --body "1:...:android:..."
gh secret set KEYSTORE_PASSWORD --body "<value>"
gh secret set KEY_ALIAS --body "<value>"
gh secret set KEY_PASSWORD --body "<value>"
```

**After loading the service account JSON as a secret, delete the local
copy.** It's a live credential; once it's safely in GitHub, keeping a
plaintext copy on disk only adds exposure if the machine is compromised.

Reference: [Encrypted secrets — GitHub Docs](https://docs.github.com/en/actions/security-guides/encrypted-secrets)

## Part 5 — The workflow itself

`.github/workflows/deploy-production.yml`:

```yaml
name: Deploy to Firebase App Distribution

on:
  push:
    branches: [production]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Generate Drift code
        run: dart run build_runner build --delete-conflicting-outputs

      - name: Decode keystore
        run: echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 -d > android/app/money-log-release.jks

      - name: Write key.properties
        run: |
          cat <<EOF > android/key.properties
          storePassword=${{ secrets.KEYSTORE_PASSWORD }}
          keyPassword=${{ secrets.KEY_PASSWORD }}
          keyAlias=${{ secrets.KEY_ALIAS }}
          storeFile=money-log-release.jks
          EOF

      - name: Build release APK (arm64)
        run: flutter build apk --release --target-platform android-arm64

      - name: Extract latest changelog entry
        run: awk '/^## /{n++} n==1' CHANGELOG.md > /tmp/release-notes.md

      - name: Upload to Firebase App Distribution
        uses: wzieba/Firebase-Distribution-Github-Action@v1
        with:
          appId: ${{ secrets.FIREBASE_APP_ID }}
          serviceCredentialsFileContent: ${{ secrets.FIREBASE_SERVICE_ACCOUNT }}
          groups: internal
          file: build/app/outputs/flutter-apk/app-release.apk
          releaseNotesFile: /tmp/release-notes.md
```

### What each step does

- **`on: push: branches: [production]`** — this workflow only ever runs
  when `production` moves. Nothing in `main` or any PR triggers it.
- **checkout / flutter-action / pub get** — identical to
  `flutter-test.yml`, standard Flutter CI bootstrap.
- **Generate Drift code** — regenerates the `*.g.dart` files
  (`build_runner`), same as CI's test workflow; these are gitignored so
  every build/CI run regenerates them fresh.
- **Decode keystore** — `KEYSTORE_BASE64` is text (GitHub secrets can't
  hold binary), so this step reverses the `base64 -w 0` encoding back into
  the real `.jks` file, written to the exact path `build.gradle.kts`
  expects (`android/app/money-log-release.jks`).
- **Write key.properties** — recreates the same file `build.gradle.kts`
  reads locally (§1.2), sourced from secrets instead of a local file.
  Exists only for the duration of this CI run; never committed, never
  cached between runs.
- **Build release APK (arm64)** — same command verified locally in §1.4/§2;
  Gradle picks up the just-written `key.properties` automatically because
  of the wiring in §1.3, so this build is signed with the real release key,
  not debug.
- **Upload to Firebase App Distribution** — authenticates using the service
  account JSON (from `FIREBASE_SERVICE_ACCOUNT`), uploads the APK to the
  app identified by `FIREBASE_APP_ID`, and notifies every tester in the
  `internal` group.

### Important notes on this approach

- **The keystore and its passwords exist in the CI runner's filesystem only
  for the duration of the job** — GitHub Actions runners are ephemeral and
  torn down after each run, so nothing persists between builds.
- **Secrets are masked in logs** — GitHub automatically redacts any secret
  value that appears in step output, but this is a safety net, not a
  reason to `echo`/print secrets deliberately.
- **`groups: internal` must match** the alias used in
  `firebase appdistribution:group:create` (§3.5) exactly, or the upload
  step will succeed but no tester will be notified.
- **This workflow does not touch `main`.** It's entirely separate from
  `flutter-test.yml`, which still gates PRs into `main`. `production` is
  meant to be a deploy-only branch — see the branch-protection plan for
  restricting who can push to it.
- **The `@v1` tag on the distribution action is a floating tag**, not a
  pinned commit. Acceptable for a personal project; for stricter
  supply-chain hygiene, pin to a commit SHA instead.

## Common errors and fixes

| Error | Cause | Fix |
|---|---|---|
| `ENOENT ... firebase-tools/lib/templates/...` | Corrupted global `firebase-tools` install | `npm install -g firebase-tools` |
| `firebase login` hangs forever | Tries to open a local browser + listen on localhost; no browser/port access in this shell | `firebase login --no-localhost`, open the printed URL manually, paste the code back |
| `Error: firebase use must be run from a Firebase project directory` | No `.firebaserc`/`firebase.json` yet, and `firebase init` is interactive-only (hangs headless) | Write `.firebaserc` and `firebase.json` directly (§3.2) |
| `Failed to list groups.` from `appdistribution:group:list` | App Distribution not yet enabled on the project | Enable it once via console (§3.4) |
| Package name mismatch when reusing an existing Firebase Android app | Project had a leftover app registration from an unrelated prototype | `firebase apps:sdkconfig ANDROID <id>` to check `package_name` before reusing; register a new app if it doesn't match |
| `apksigner verify` shows `CN=Android Debug, O=Android` | `key.properties`/keystore not found at build time, so Gradle silently fell back to debug signing | Confirm `android/key.properties` exists and `storeFile` path resolves; re-run `apksigner verify` after |
| Gradle daemon crash: `Out of Memory Error ... Native memory allocation (mmap) failed` | `org.gradle.jvmargs=-Xmx8G` too high for available RAM (e.g. an 11GB machine) | Lower to `-Xmx3G` (and matching `-XX:MaxMetaspaceSize`/`-XX:ReservedCodeCacheSize`) in `android/gradle.properties` |
| `unknown option '--group'` on `firebase appdistribution:testers:add` | CLI flag name changed across versions | Run `firebase appdistribution:testers:add --help` to check current flags, or add testers via console instead |

## Official documentation

- [Firebase App Distribution — Android](https://firebase.google.com/docs/app-distribution/android/distribute-console)
- [Firebase CLI reference](https://firebase.google.com/docs/cli)
- [Android app signing](https://developer.android.com/studio/publish/app-signing)
- [Flutter — Build and release an Android app](https://docs.flutter.dev/deployment/android)
- [GitHub Actions — Encrypted secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [GitHub Actions — Branch protection rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
- [wzieba/Firebase-Distribution-Github-Action](https://github.com/wzieba/Firebase-Distribution-Github-Action)
