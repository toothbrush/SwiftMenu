# Releasing

`MARKETING_VERSION` in `SwiftMenu.xcodeproj/project.pbxproj` is the source of truth for the version.
Set `V` to the new version, then:

```sh
V=0.7.2

# 1. Bump version (both app + test targets).
perl -pi -e "s/MARKETING_VERSION = .*/MARKETING_VERSION = $V;/" SwiftMenu.xcodeproj/project.pbxproj

# 2. Build, notarize, staple, zip, and update the Nix package version/hash.
make
# -> build/SwiftMenu-v$V.zip (also copied to updates/)
# -> package.nix updated to match the signed release ZIP

# 3. Commit the version and Nix metadata together, tag, and push.
git add SwiftMenu.xcodeproj/project.pbxproj package.nix
git commit -m "Release $V"
git tag "v$V"
git push && git push --tags

# 4. Publish the ZIP referenced by package.nix.
gh release create "v$V" "updates/SwiftMenu-v$V.zip" --title "v$V" --notes "One sentence describing the change."

# 5. Check the published Nix package.
nix build "github:toothbrush/SwiftMenu/v$V"
```

Nix installs the signed release without modifying the bundle. Do not patch its
executable or strip its binaries, as either would invalidate the signature.
