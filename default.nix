# Similar to nixpkgs, this defines dypkgs, which contains library functions,
# the package builder, and package definitions.

{ callPackage }:
let
  dypkgs = {
    buildDyRustModule = callPackage ./builder.nix { };

    pkgs = callPackage ./pkgs { inherit dypkgs; };
  };
in
dypkgs // dypkgs.pkgs
