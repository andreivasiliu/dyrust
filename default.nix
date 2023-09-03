# Similar to nixpkgs, this defines dypkgs, which contains library functions,
# the package builder, and package definitions.

{ callPackage }:
let
  dypkgs = rec {
    libstd = callPackage ./libstd.nix { };
    buildDyRustModule = callPackage ./builder.nix { inherit libstd; };

    pkgs = callPackage ./pkgs { inherit dypkgs; };
  };
in
dypkgs // dypkgs.pkgs
