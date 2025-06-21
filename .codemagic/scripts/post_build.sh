#!/bin/bash

# Post-build script for Bald Collector

set -e

echo "📊 Running post-build tasks for Bald Collector..."

# Function to get file size in human readable format
get_file_size() {
    local file=$1
    if [ -f "$file" ]; then
        if command -v numfmt >/dev/null 2>&1; then
            ls -la "$file" | awk '{print $5}' | numfmt --to=iec
        else
            ls -lah "$file" | awk '{print $5}'
        fi
    else
        echo "File not found"
    fi
}

# Android post-build tasks
android_post_build() {
    echo "📱 Android post-build tasks..."
    
    APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
    AAB_PATH="build/app/outputs/bundle/release/app-release.aab"
    
    if [ -f "$APK_PATH" ]; then
        APK_SIZE=$(get_file_size "$APK_PATH")
        echo "✅ APK built successfully - Size: $APK_SIZE"
        echo "APK location: $APK_PATH"
    else
        echo "❌ APK build failed - file not found at $APK_PATH"
    fi
    
    if [ -f "$AAB_PATH" ]; then
        AAB_SIZE=$(get_file_size "$AAB_PATH")
        echo "✅ AAB built successfully - Size: $AAB_SIZE"
        echo "AAB location: $AAB_PATH"
    else
        echo "❌ AAB build failed - file not found at $AAB_PATH"
    fi
}

# iOS post-build tasks
ios_post_build() {
    echo "🍎 iOS post-build tasks..."
    
    IPA_PATH="build/ios/ipa/Bald Collector.ipa"
    
    if [ -f "$IPA_PATH" ]; then
        IPA_SIZE=$(get_file_size "$IPA_PATH")
        echo "✅ IPA built successfully - Size: $IPA_SIZE"
        echo "IPA location: $IPA_PATH"
    else
        echo "❌ IPA build failed - file not found at $IPA_PATH"
    fi
}

# Generate build report
generate_build_report() {
    echo "📋 Generating build report..."
    
    REPORT_FILE="build_report.txt"
    
    cat > "$REPORT_FILE" << EOF
Bald Collector Build Report
=====================
Build Date: $(date)
Build Number: ${CM_BUILD_NUMBER:-"N/A"}
Git Commit: ${CM_COMMIT:-"N/A"}
Git Branch: ${CM_BRANCH:-"N/A"}

Flutter Info:
$(flutter --version)

EOF
    
    if [ "$CM_BUILD_PLATFORM" = "android" ] || [ -z "$CM_BUILD_PLATFORM" ]; then
        echo "Android Build Results:" >> "$REPORT_FILE"
        if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
            echo "- APK: ✅ $(get_file_size build/app/outputs/flutter-apk/app-release.apk)" >> "$REPORT_FILE"
        else
            echo "- APK: ❌ Failed" >> "$REPORT_FILE"
        fi
        
        if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
            echo "- AAB: ✅ $(get_file_size build/app/outputs/bundle/release/app-release.aab)" >> "$REPORT_FILE"
        else
            echo "- AAB: ❌ Failed" >> "$REPORT_FILE"
        fi
        echo "" >> "$REPORT_FILE"
    fi
    
    if [ "$CM_BUILD_PLATFORM" = "ios" ] || [ -z "$CM_BUILD_PLATFORM" ]; then
        echo "iOS Build Results:" >> "$REPORT_FILE"
        if [ -f "build/ios/ipa/Bald Collector.ipa" ]; then
            echo "- IPA: ✅ $(get_file_size build/ios/ipa/Bald Collector.ipa)" >> "$REPORT_FILE"
        else
            echo "- IPA: ❌ Failed" >> "$REPORT_FILE"
        fi
    fi
    
    echo "📊 Build report generated: $REPORT_FILE"
    cat "$REPORT_FILE"
}

# Main function
main() {
    echo "🔍 Starting post-build analysis..."
    
    if [ "$CM_BUILD_PLATFORM" = "android" ] || [ -z "$CM_BUILD_PLATFORM" ]; then
        android_post_build
    fi
    
    if [ "$CM_BUILD_PLATFORM" = "ios" ] || [ -z "$CM_BUILD_PLATFORM" ]; then
        ios_post_build
    fi
    
    generate_build_report
    
    echo "✅ Post-build tasks completed!"
}

# Run main function
main "$@"