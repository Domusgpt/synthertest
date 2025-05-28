#!/bin/bash

echo "🎯 SYNTHER REAL TESTING SCRIPT 🎯"
echo "=================================="

# Navigate to project directory
cd /mnt/c/Users/millz/Desktop/Synther

echo ""
echo "📋 1. CHECKING FLUTTER INSTALLATION..."
flutter --version

echo ""
echo "📋 2. GETTING DEPENDENCIES..."
flutter pub get

echo ""
echo "📋 3. ANALYZING CODE QUALITY..."
flutter analyze --no-fatal-infos

echo ""
echo "📋 4. RUNNING UNIT TESTS..."
flutter test --reporter=expanded

echo ""
echo "📋 5. CHECKING WEB BUILD..."
flutter build web --debug --verbose

echo ""
echo "📋 6. CHECKING ANDROID BUILD..."
flutter build apk --debug --verbose

echo ""
echo "📋 7. RUNNING APP IN CHROME (if available)..."
timeout 30s flutter run -d chrome --debug || echo "Chrome test completed or timed out"

echo ""
echo "📋 8. CHECKING PROJECT STRUCTURE..."
echo "Core files:"
ls -la lib/core/
echo ""
echo "Features:"
ls -la lib/features/
echo ""
echo "Assets:"
ls -la assets/ 2>/dev/null || echo "No assets directory"

echo ""
echo "📋 9. CHECKING PUBSPEC DEPENDENCIES..."
grep -A 20 "dependencies:" pubspec.yaml

echo ""
echo "🎯 REAL TESTING COMPLETE!"
echo "Review output above for actual results"