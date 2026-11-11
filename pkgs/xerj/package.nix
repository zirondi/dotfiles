{
  lib,
  stdenvNoCC,
  fetchurl,
}:

# XERJ: local search engine the agents use for reference coding (see CLAUDE.md).
# Not in nixpkgs, so the static release binary is installed as-is. To update,
# bump the version and convert each target's published .sha256 digest with
# `nix hash convert --hash-algo sha256 --to sri <hex>`.
let
  version = "1.0.0-rc.100";
  targets = {
    aarch64-darwin = {
      triple = "aarch64-apple-darwin";
      hash = "sha256-yI/cuZxBVdL3JgE4w6WJjQ889rB80giJUTf/A8UrnRo=";
    };
    x86_64-linux = {
      triple = "x86_64-unknown-linux-musl";
      hash = "sha256-SxKkfoQz6dAdKz9QWxezQqbijUHtqr0nTrpadZ6c3h4=";
    };
  };
  target =
    targets.${stdenvNoCC.hostPlatform.system}
      or (throw "xerj: no release binary for ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "xerj";
  inherit version;

  src = fetchurl {
    url = "https://github.com/xerj-org/xerj/releases/download/v${version}/xerj-${version}-${target.triple}.tar.gz";
    inherit (target) hash;
  };

  installPhase = ''
    runHook preInstall
    install -Dm755 xerj $out/bin/xerj
    runHook postInstall
  '';

  meta = {
    description = "Local search engine for AI agents";
    homepage = "https://xerj.org/";
    license = lib.licenses.asl20;
    platforms = builtins.attrNames targets;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "xerj";
  };
}
