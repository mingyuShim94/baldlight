#!/bin/bash

# Codemagic Environment Setup Script for Bald Collector

set -e

echo "🚀 Setting up Bald Collector build environment..."

# Android environment setup
setup_android() {
    echo "📱 Setting up Android environment..."
    
    # Create key.properties for Android signing
    if [ -n "$CM_KEYSTORE_PASSWORD" ]; then
        echo "Creating Android key.properties..."
        cat > android/key.properties << EOF
storePassword=$CM_KEYSTORE_PASSWORD
keyPassword=$CM_KEY_PASSWORD
keyAlias=$CM_KEY_ALIAS
storeFile=$CM_KEYSTORE_PATH
EOF
    else
        echo "⚠️  Android keystore environment variables not set"
    fi
}

# iOS environment setup
setup_ios() {
    echo "🍎 Setting up iOS environment..."
    
    # Copy export options
    if [ -f ".codemagic/ios/export_options.plist" ]; then
        echo "Copying iOS export options..."
        cp .codemagic/ios/export_options.plist ios/ExportOptions.plist
    fi
    
    # Set up provisioning profiles
    if [ -n "$CM_PROVISIONING_PROFILE" ]; then
        echo "iOS provisioning profile configured: $CM_PROVISIONING_PROFILE"
    else
        echo "⚠️  iOS provisioning profile not set"
    fi
}

# Flutter environment setup
setup_flutter() {
    echo "🐦 Setting up Flutter environment..."
    
    # Get Flutter dependencies
    echo "Getting Flutter dependencies..."
    flutter pub get
    
    # Generate icons if needed
    if [ -f "flutter_launcher_icons.yaml" ]; then
        echo "Generating app icons..."
        flutter pub run flutter_launcher_icons
    fi
    
    # Run flutter doctor
    echo "Running Flutter doctor..."
    flutter doctor
}

# Version management
setup_version() {
    echo "📦 Setting up version management..."
    
    # Extract version from pubspec.yaml
    VERSION=$(grep '^version:' pubspec.yaml | cut -d ' ' -f 2)
    echo "Current app version: $VERSION"
    
    # Set environment variables for build
    export APP_VERSION=$VERSION
    export BUILD_NUMBER=${CM_BUILD_NUMBER:-1}
    
    echo "Build version: $APP_VERSION+$BUILD_NUMBER"
}

# Main setup function
main() {
    echo "🔧 Starting Bald Collector environment setup..."
    
    setup_version
    setup_flutter
    
    if [ "$CM_BUILD_PLATFORM" = "android" ] || [ -z "$CM_BUILD_PLATFORM" ]; then
        setup_android
    fi
    
    if [ "$CM_BUILD_PLATFORM" = "ios" ] || [ -z "$CM_BUILD_PLATFORM" ]; then
        setup_ios
    fi
    
    echo "✅ Environment setup completed successfully!"
}

# Run main function
main "$@"