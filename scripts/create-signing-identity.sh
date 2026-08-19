#!/bin/bash
# create-signing-identity.sh
#
# Creates a self-signed code-signing certificate ("BongoCat Menubar Development")
# and imports it into the login keychain.
#
# Why: ad-hoc signing (`codesign --sign -`) embeds the code hash, which changes
# on every build, so macOS treats each update as a new app and re-requests
# Accessibility permission. A stable certificate makes TCC recognize the app
# across rebuilds and upgrades, so the permission is granted once.
#
# Run once on each machine that builds the app:
#   ./scripts/create-signing-identity.sh
#
# Afterwards `make build` automatically uses the identity when present.
# (macOS may prompt for your login password to allow keychain access.)

set -euo pipefail

IDENTITY="BongoCat Menubar Development"
DAYS=3650

if security find-identity -v -p codesigning | grep -q "$IDENTITY"; then
    echo "Identity '$IDENTITY' already exists in the keychain. Nothing to do."
    exit 0
fi

TMPDIR_CERT="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_CERT"' EXIT

echo "==> Generating self-signed code-signing certificate"
openssl req -x509 -newkey rsa:2048 -nodes \
    -keyout "$TMPDIR_CERT/key.pem" \
    -out "$TMPDIR_CERT/cert.pem" \
    -days "$DAYS" \
    -subj "/CN=$IDENTITY" \
    -addext "keyUsage=digitalSignature" \
    -addext "extendedKeyUsage=codeSigning" \
    2>/dev/null

echo "==> Packaging as .p12 (export password: bongocat)"
# -legacy: OpenSSL 3 defaults to AES/PBES2 which macOS `security import` cannot read.
openssl pkcs12 -export -legacy \
    -inkey "$TMPDIR_CERT/key.pem" \
    -in "$TMPDIR_CERT/cert.pem" \
    -out "$TMPDIR_CERT/cert.p12" \
    -passout pass:bongocat

echo "==> Importing into login keychain (you may be prompted for your password)"
security import "$TMPDIR_CERT/cert.p12" \
    -k ~/Library/Keychains/login.keychain-db \
    -P bongocat \
    -T /usr/bin/codesign

echo ""
echo "==> Done. Verify with:"
echo "    security find-identity -v -p codesigning"
echo "    codesign -dvvv \".build/debug/BongoCat Menubar.app\"  # after make build"
