{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:

# NotProton: stands in for Valve's Proton in the Mac Steam client, so games
# run through CrossOver without the Windows build of Steam. No Homebrew cask
# exists; the signed app comes from the GitHub release. Its built-in updater
# cannot write to the store: bump version and hash here instead.
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "notproton";
  version = "1.2.0";

  src = fetchurl {
    url = "https://github.com/NotProtonNot/NotProton/releases/download/v${finalAttrs.version}/NotProton.zip";
    hash = "sha256-wHdHParpoEmlHdA5opCMfAYfYw1YYop0rE6Kn25bLgk=";
  };

  nativeBuildInputs = [ unzip ];
  sourceRoot = ".";
  dontFixup = true; # keeps the code signature intact

  installPhase = ''
    mkdir -p $out/Applications
    cp -R NotProton.app $out/Applications/
  '';

  meta = {
    description = "Proton replacement for the macOS Steam client, for use with CrossOver";
    homepage = "https://github.com/NotProtonNot/NotProton";
    platforms = lib.platforms.darwin;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
