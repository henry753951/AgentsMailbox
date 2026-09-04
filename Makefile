DEVELOPER_DIR ?= /Applications/Xcode.app/Contents/Developer
PROJECT := AgentsMailbox.xcodeproj
SCHEME := AgentsMailbox
DERIVED_DATA := .derived

.PHONY: build check format lint clean

build:
	DEVELOPER_DIR="$(DEVELOPER_DIR)" xcodebuild -project "$(PROJECT)" -scheme "$(SCHEME)" -configuration Debug -derivedDataPath "$(DERIVED_DATA)" build CODE_SIGNING_ALLOWED=NO

format:
	DEVELOPER_DIR="$(DEVELOPER_DIR)" xcrun swift-format format --recursive --in-place AgentsMailbox

lint:
	DEVELOPER_DIR="$(DEVELOPER_DIR)" xcrun swift-format lint --recursive AgentsMailbox

check: lint build

clean:
	DEVELOPER_DIR="$(DEVELOPER_DIR)" xcodebuild -project "$(PROJECT)" -scheme "$(SCHEME)" -derivedDataPath "$(DERIVED_DATA)" clean
