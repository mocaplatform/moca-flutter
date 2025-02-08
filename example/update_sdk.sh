#!/bin/bash

rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf ~/Library/Caches/CocoaPods
cd ios
pod deintegrate
rm Podfile.locki 2>/dev/null
rm -rf Pods 2>/dev/null
pod install --repo-update
flutter pub get
cd ..
flutter clean
flutter pub get
flutter build ios --config-only
flutter build ios

