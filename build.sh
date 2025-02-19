#!/bin/bash
mkdir -p "BrightnessControlLite.app/Contents/MacOS"
mkdir -p "BrightnessControlLite.app/Contents/Resources"

swiftc -F /System/Library/PrivateFrameworks -framework CoreDisplay -import-objc-header Bridging-Header.h main.swift backend.swift ui.swift Arm64ServiceFetcher.swift -o BrightnessControlLite

mv BrightnessControlLite "BrightnessControlLite.app/Contents/MacOS/BrightnessControlLite"