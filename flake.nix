{
  description = "SwiftMenu macOS chooser";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { nixpkgs, ... }:
    let
      systems = [ "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in {
      packages = forAllSystems (system:
        let package = nixpkgs.legacyPackages.${system}.callPackage ./package.nix { };
        in {
          swiftmenu = package;
          default = package;
        });
    };
}
