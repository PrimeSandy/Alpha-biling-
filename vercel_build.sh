#!/bin/bash

# Download Flutter
git clone https://github.com/flutter/flutter.git --depth 1 -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Get dependencies and build
flutter doctor
flutter pub get
flutter build web --release

# Note: Vercel will look for the output in build/web
