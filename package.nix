{ lib, stdenvNoCC, fetchurl, unzip }:

stdenvNoCC.mkDerivation rec {
  pname = "swiftmenu";
  version = "0.7.3";

  # Keep the upstream Developer ID signature and notarization intact.
  src = fetchurl {
    url = "https://github.com/toothbrush/SwiftMenu/releases/download/v${version}/SwiftMenu-v${version}.zip";
    hash = "sha256-sOSzDDMsF0tXyB5l+bQVOElse404vPHr/xRc1WUngyw=";
  };

  nativeBuildInputs = [ unzip ];
  sourceRoot = ".";
  # ditto ZIPs carry AppleDouble metadata files that are not signed resources.
  postUnpack = ''
    find . -name '._*' -delete
  '';
  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/Applications"
    cp -R SwiftMenu.app "$out/Applications/SwiftMenu.app"
    runHook postInstall
  '';

  meta = {
    description = "A macOS chooser for passwords and TOTP codes";
    homepage = "https://github.com/toothbrush/SwiftMenu";
    platforms = lib.platforms.darwin;
  };
}
