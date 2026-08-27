# Firebase iOS (App Store)

Le fichier `Runner/GoogleService-Info.plist` est préparé avec le projet Firebase **akadex-1**
(même projet que Android).

## Une étape obligatoire

1. Ouvre [Firebase Console](https://console.firebase.google.com/) → projet **akadex-1**
2. **Add app** → iOS → Bundle ID `com.akadex.akadex`
3. Télécharge le vrai `GoogleService-Info.plist`
4. Remplace `ios/Runner/GoogleService-Info.plist` (surtout la clé `GOOGLE_APP_ID`)

Sans cette étape, Crashlytics / FCM iOS peuvent échouer silencieusement au démarrage
(l’app reste utilisable ; le bootstrap Flutter ignore l’erreur).

## Build IPA

```bash
flutter build ipa
```
