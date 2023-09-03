# Copy libstd-*.so from the rustc package into its own smaller package.
# That's because rustc weighs around 750MB, while libstd-*.so is just 6MB.

{ stdenv, rustc }:

stdenv.mkDerivation {
  name = "libstd-rust";
  version = "1.0.0";
  src = rustc;

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/lib
    cp ${rustc}/lib/libstd-*.so $out/lib
  '';
}
