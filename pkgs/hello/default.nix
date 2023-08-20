{ dypkgs }:

dypkgs.buildDyRustModule {
  name = "hello";
  type = "lib";

  src = ./.;
}
