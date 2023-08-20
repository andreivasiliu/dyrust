{ dypkgs }:

dypkgs.buildDyRustModule {
  name = "hello_again";
  type = "lib";

  src = ./.;
}
