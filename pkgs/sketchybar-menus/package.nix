{ lib, stdenv }:

# Helper for configs/sketchybar: lists and opens the focused app's menus
stdenv.mkDerivation {
  pname = "sketchybar-menus";
  version = "1.4";
  src = ./.;

  buildPhase = ''
    $CC -O2 -Wall -framework ApplicationServices -o sketchybar-menus menus.c
  '';
  installPhase = ''
    install -Dm755 sketchybar-menus $out/bin/sketchybar-menus
  '';

  meta = {
    description = "List and open the focused app's menu bar menus for SketchyBar";
    license = lib.licenses.mit;
    platforms = lib.platforms.darwin;
    mainProgram = "sketchybar-menus";
  };
}
