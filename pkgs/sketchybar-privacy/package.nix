{ lib, stdenv }:

# Helper for configs/sketchybar: reports whether a microphone or camera is in use
stdenv.mkDerivation {
  pname = "sketchybar-privacy";
  version = "1.0";
  src = ./.;

  buildPhase = ''
    $CC -O2 -Wall -framework CoreAudio -framework CoreMediaIO -framework CoreFoundation \
      -o sketchybar-privacy privacy.c
  '';
  installPhase = ''
    install -Dm755 sketchybar-privacy $out/bin/sketchybar-privacy
  '';

  meta = {
    description = "Report microphone and camera use as JSON for SketchyBar";
    license = lib.licenses.mit;
    platforms = lib.platforms.darwin;
    mainProgram = "sketchybar-privacy";
  };
}
