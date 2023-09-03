# This is the dynamic Rust package builder, and is used by the packages
# in ./pkgs/ to create their derivations.

{ stdenv, removeReferencesTo, rustc, libstd }: { name, src, type, ... }@attrs:

assert type == "bin" || type == "lib";

stdenv.mkDerivation (rec {
  inherit name src;

  edition = attrs.edition or "2021";

  rustDependencies = attrs.dependencies or [];

  # Add the rustc compiler to the build dependencies
  nativeBuildInputs = [ removeReferencesTo rustc ];
  # And the extracted standard library to runtime dependencies
  buildInputs = [ libstd ] ++ rustDependencies;

  crateType = if type == "bin" then "bin" else "dylib";
  srcFile = if type == "bin" then "main.rs" else "lib.rs";
  outDir = type;

  externList = map (dep: "--extern ${dep.name}=${dep}/lib/lib${dep.name}.so") rustDependencies;
  externs = builtins.concatStringsSep " " externList;

  # Define the default build phase (which can be overridden)
  buildPhase = attrs.buildPhase or ''
    echo "Building the dynamic Rust module..."
    mkdir -p $out/$type
    (
      set -x;
      rustc \
        --crate-name "$name" \
        --edition $edition \
        --crate-type $crateType \
        -C prefer-dynamic \
        $externs \
        --out-dir "$out/$outDir" \
        "$src/$srcFile"
    )
  '';

  # The rustc package is really big, remove it and leave just libstd
  installPhase = ''
    remove-references-to -t ${rustc} $out/$outDir/*
  '';

  # Pass along any other attributes to the derivation
  # inherit (attrs) meta description doCheck installPhase;
})
