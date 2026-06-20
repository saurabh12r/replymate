#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# 1. Download Flutter SDK (stable branch) if not cached
if [ ! -d "flutter" ]; then
  echo "Cloning Flutter SDK..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
else
  echo "Using cached Flutter SDK..."
fi

# 2. Add Flutter to PATH
export PATH="$PATH:$(pwd)/flutter/bin"

# 3. Disable analytics & pre-cache web platform binaries
flutter config --no-analytics
flutter precache --web

# 4. Run the production web build
echo "Running Flutter Web release build..."
flutter build web --release
