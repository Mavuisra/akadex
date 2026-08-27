#!/usr/bin/env bash
# Génère un keystore de production Akadex (ne pas committer le .jks).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ANDROID="$ROOT/android"
KEYSTORE="$ANDROID/upload-keystore.jks"
PROPS="$ANDROID/key.properties"

if [[ -f "$KEYSTORE" ]]; then
  echo "Keystore déjà présent: $KEYSTORE"
  exit 0
fi

STORE_PASS="${ANDROID_KEYSTORE_PASSWORD:-akadexUploadChangeMe}"
KEY_PASS="${ANDROID_KEY_PASSWORD:-$STORE_PASS}"
ALIAS="${ANDROID_KEY_ALIAS:-upload}"

keytool -genkeypair -v \
  -keystore "$KEYSTORE" \
  -storetype JKS \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias "$ALIAS" \
  -storepass "$STORE_PASS" \
  -keypass "$KEY_PASS" \
  -dname "CN=Akadex, OU=Mobile, O=Akadex, L=Kinshasa, C=CD"

cat > "$PROPS" <<EOF
storePassword=$STORE_PASS
keyPassword=$KEY_PASS
keyAlias=$ALIAS
storeFile=upload-keystore.jks
EOF

echo "Créé:"
echo "  $KEYSTORE"
echo "  $PROPS"
echo "Ajoute ces secrets GitHub pour CI:"
echo "  ANDROID_KEYSTORE_BASE64=\$(base64 -w0 \"$KEYSTORE\")"
echo "  ANDROID_KEYSTORE_PASSWORD / ANDROID_KEY_PASSWORD / ANDROID_KEY_ALIAS=$ALIAS"
