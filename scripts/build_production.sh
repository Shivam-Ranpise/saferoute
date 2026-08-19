#!/usr/bin/env bash
set -e

echo "=========================================="
echo "  SafeRoute Production Build Pipeline     "
echo "=========================================="

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$( dirname "$SCRIPT_DIR" )"

echo ""
echo "[1/3] Verifying saferoute_core..."
cd "$ROOT_DIR/packages/saferoute_core"
flutter pub get
flutter test
flutter analyze

echo ""
echo "[2/3] Verifying saferoute_app (Mobile)..."
cd "$ROOT_DIR/apps/saferoute_app"
flutter pub get
flutter test
flutter analyze

echo ""
echo "[3/3] Verifying saferoute_admin (Web)..."
cd "$ROOT_DIR/apps/saferoute_admin"
flutter pub get
flutter test
flutter analyze

echo ""
echo "=========================================="
echo "  SafeRoute Monorepo: ALL BUILDS VERIFIED "
echo "=========================================="
