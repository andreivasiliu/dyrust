{ dypkgs }:

dypkgs.buildDyRustModule {
  name = "sample_bin";
  type = "bin";

  dependencies = [
    dypkgs.pkgs.hello
    dypkgs.pkgs.hello_again
  ];

  src = ./.;
}
