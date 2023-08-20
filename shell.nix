# This file is used by `nix-shell`, which is a convenient way to get a shell
# with all dependencies pulled in.

let
  nixpkgs = import <nixpkgs> { };
  dypkgs = nixpkgs.callPackage ./. { };
  shell = nixpkgs.mkShell {
    # On a `nix-shell` with no arguments, these packages will be made available.
    buildInputs = [ dypkgs.sample_bin ];
  };
in
  # Merge the shell with the list of packages, so that `nix-shell -A hello`
  # also works, which will bring that specific package's dependencies.
  shell // dypkgs.pkgs
