#!/usr/bin/env bash
set -euo pipefail
flutter create . --platforms=android,ios,web
flutter pub get
