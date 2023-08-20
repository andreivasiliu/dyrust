# This defines dypkgs.pkgs, which contains a set of all packages.

{ dypkgs, callPackage }:
let
  paths = {
    hello = ./hello;
    hello_again = ./hello_again;
    sample_bin = ./sample_bin;
  };
in
  builtins.mapAttrs (name: path: callPackage path { inherit dypkgs; }) paths
