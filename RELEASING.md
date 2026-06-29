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

# 6. Create the GitHub release with the zip (one-sentence note, no changelog)
gh release create "v$V" "updates/SwiftMenu-v$V.zip" --title "v$V" --notes "One sentence describing the change."

# 7. Bump the homebrew cask in the tap and push.
#    Edit version + sha256 in place rather than overwriting with updates/swiftmenu.rb,
#    so hand-made tap fixes (e.g. depends_on) survive. Commit style: "swiftmenu: $V".
TAP=~/src/toothbrush/homebrew-toothbrush
SHA=$(sha256sum updates/SwiftMenu-v$V.zip | cut -d' ' -f1)
perl -pi -e "s/version \".*\"/version \"$V\"/; s/sha256 \".*\"/sha256 \"$SHA\"/" "$TAP/Casks/swiftmenu.rb"
git -C "$TAP" commit -am "swiftmenu: $V" && git -C "$TAP" push
```
