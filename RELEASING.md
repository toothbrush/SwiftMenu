# Releasing

`MARKETING_VERSION` in `SwiftMenu.xcodeproj/project.pbxproj` is the source of truth for the version.
Set `V` to the new version, then:

```sh
V=0.7.0

# 1. Bump version (both app + test targets)
perl -pi -e "s/MARKETING_VERSION = .*/MARKETING_VERSION = $V;/" SwiftMenu.xcodeproj/project.pbxproj

# 2. Commit
git commit -am "Bump to $V"

# 3. Tag
git tag "v$V"

# 4. Push
git push && git push --tags

# 5. Build: archive, notarise, staple, zip, regenerate cask
make
# -> build/SwiftMenu-v$V.zip  (also copied to updates/)
# -> updates/swiftmenu.rb     (regenerated homebrew cask)

# 6. Upload to GitHub release
gh release create "v$V" "build/SwiftMenu-v$V.zip" --title "v$V" --generate-notes

# 7. Update the homebrew cask: copy updates/swiftmenu.rb into the tap and push
```
