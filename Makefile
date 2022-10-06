# This is adapted from https://github.com/exelban/stats/blob/master/Makefile

APP = SwiftMenu
BUNDLE_ID = com.rustlingbroccoli.SwiftMenu

TEAM_ID := $(shell security find-certificate -c "Developer ID Application:" | grep "alis" | awk 'NF { print $$NF }' | tr -d \(\)\")

BUILD_PATH = $(PWD)/build
APP_PATH = "$(BUILD_PATH)/$(APP).app"
ZIP_PATH = "$(BUILD_PATH)/$(APP).zip"

AC_USERNAME := $(shell pass spotiqueue-itc-signing | grep email | awk '{print $$2}')
export AC_PASSWORD := $(shell pass spotiqueue-itc-signing | grep app-specific-pass | awk '{print $$2}')

.PHONY: build
build: archive notarize sign make-zip

# --- MAIN WORKFLOW FUNCTIONS --- #

.PHONY: archive
archive: clean
	@echo "Exporting application archive..."

	xcodebuild \
		-scheme $(APP) \
		-destination 'generic/platform=OS X' \
		-configuration Release archive \
		-archivePath $(BUILD_PATH)/$(APP).xcarchive

	@echo "Application built, starting the export archive..."

	xcodebuild -exportArchive \
		-exportOptionsPlist "$(PWD)/ExportOptions.plist" \
		-archivePath $(BUILD_PATH)/$(APP).xcarchive \
		-exportPath $(BUILD_PATH)

	ditto -c -k --keepParent $(APP_PATH) $(ZIP_PATH)

	@echo "Project archived successfully"

.PHONY: notarize
notarize:
	@echo "Submitting app for notarization..."
	@xcrun notarytool store-credentials AC_PASSWORD_SWIFTMENU \
	  --apple-id ${AC_USERNAME} \
	  --team-id ${TEAM_ID} \
	  --password ${AC_PASSWORD}
	xcrun notarytool submit ${ZIP_PATH} \
	  --team-id ${TEAM_ID} \
	  --apple-id ${AC_USERNAME} \
	  --keychain-profile AC_PASSWORD_SWIFTMENU \
	  --wait
	@echo "Application sent to the notarization center"

.PHONY: sign
sign:
	@echo "Checking if package is approved by Apple..."
	@xcrun notarytool store-credentials AC_PASSWORD_SWIFTMENU \
	  --apple-id ${AC_USERNAME} \
	  --team-id ${TEAM_ID} \
	  --password ${AC_PASSWORD}
	xcrun notarytool history \
	  --team-id ${TEAM_ID} \
	  --apple-id ${AC_USERNAME} \
	  --keychain-profile AC_PASSWORD_SWIFTMENU \
	  --output-format json

	@echo "Going to staple an application..."

	xcrun stapler staple $(APP_PATH)
	spctl -a -t exec -vvv $(APP_PATH)

	@echo "SwiftMenu successfully stapled"

.PHONY: make-zip
make-zip: VERSION = $(shell /usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$(APP_PATH)/Contents/Info.plist")
make-zip: sign
	ditto -c -k --keepParent $(APP_PATH) $(ZIP_PATH)
	mkdir -p updates/
	cp -v $(ZIP_PATH) updates/SwiftMenu-v$(VERSION).zip

.PHONY: prepare-dSYM
prepare-dSYM:
	@echo "Zipping dSYMs..."
	cd $(BUILD_PATH)/SwiftMenu.xcarchive/dSYMs && zip -r $(PWD)/dSYMs.zip .
	@echo "Created zip with dSYMs"

# --- HELPERS --- #

.PHONY: clean
clean:
	rm -rf $(BUILD_PATH)
	-rm $(PWD)/dSYMs.zip
	-rm $(PWD)/SwiftMenu.dmg

.PHONY: next-version
next-version:
	versionNumber=$$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$(PWD)/SwiftMenu/Info.plist") ;\
	@echo "Actual version is: $$versionNumber" ;\
	versionNumber=$$((versionNumber + 1)) ;\
	@echo "Next version is: $$versionNumber" ;\
	/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $$versionNumber" "$(PWD)/SwiftMenu/Info.plist" ;\
