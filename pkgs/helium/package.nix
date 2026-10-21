{
  lib,
  appimageTools,
  fetchurl,
}:

# Helium browser for Linux: not in nixpkgs, so the official AppImage is wrapped.
# macOS gets it from Homebrew (helium-browser cask). To update, bump the version
# and take the new hash from the release's x86_64 AppImage digest
let
  pname = "helium";
  version = "0.19.4.1";
  src = fetchurl {
    url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-x86_64.AppImage";
    hash = "sha256-Wy2zkrPth/JKqESTYFnWisqYvCBUjqqg3s+jwoCioKc=";
  };
  contents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  # The AppImage's desktop entry already runs `helium`, the wrapper's name
  extraInstallCommands = ''
    install -Dm444 ${contents}/helium.desktop $out/share/applications/helium.desktop
    cp -r ${contents}/usr/share/icons $out/share/
  '';

  meta = {
    description = "Chromium-based web browser";
    homepage = "https://helium.computer/";
    license = lib.licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
    mainProgram = "helium";
  };
}
