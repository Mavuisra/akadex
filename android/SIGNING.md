# Android release signing (Akadex)

## Local

```bash
# Git Bash / WSL / macOS / Linux
bash scripts/generate_android_keystore.sh
```

Windows (PowerShell) :

```powershell
cd android
keytool -genkeypair -v -keystore upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload -storepass CHANGE_ME -keypass CHANGE_ME -dname "CN=Akadex, OU=Mobile, O=Akadex, L=Kinshasa, C=CD"
Copy-Item key.properties.example key.properties
# Éditer key.properties avec le même mot de passe
```

Puis :

```bash
flutter build apk --release
```

Ne **jamais** committer `android/key.properties` ni `*.jks` / `*.keystore`.

## GitHub Actions (CI)

Secrets à ajouter sur le repo :

| Secret | Valeur |
|--------|--------|
| `ANDROID_KEYSTORE_BASE64` | `base64 -w0 android/upload-keystore.jks` |
| `ANDROID_KEYSTORE_PASSWORD` | store password |
| `ANDROID_KEY_PASSWORD` | key password (souvent identique) |
| `ANDROID_KEY_ALIAS` | `upload` |

Sans ces secrets, le workflow build en **fallback debug** (warning).

## Crashlytics

`firebase_crashlytics` + plugin Gradle `com.google.firebase.crashlytics` sont branchés. Collection active hors debug ; `google-services.json` doit correspondre au projet Firebase.
