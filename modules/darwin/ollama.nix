{ config, lib, ... }:

{
  # --- Ollama Local LLM Inference ---
  # Runs as a launchd user agent so it starts automatically on login.
  # Listens on 0.0.0.0:11434 so other nodes can reach it over the Tailscale mesh.
  # SECURITY: this binds EVERY interface, so the home LAN can reach it too.
  # It is not exposed to the public internet (no port forward / tunnel).

  launchd.user.agents.ollama = {
    serviceConfig = {
      Label = "com.zirondi.ollama";
      ProgramArguments = [
        "/opt/homebrew/bin/ollama"
        "serve"
      ];
      EnvironmentVariables = {
        OLLAMA_HOST = "0.0.0.0:11434";
        OLLAMA_NUM_CTX = "32768";
      };
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "/tmp/ollama.log";
      StandardErrorPath = "/tmp/ollama.err.log";
    };
  };

  home-manager.users.zirondi =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      # Activation script to automatically ensure all local Ollama models have 32k context for OpenCode
      home.activation.buildOllamaModels = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        OLLAMA_BIN="/opt/homebrew/bin/ollama"
        if [ -x "$OLLAMA_BIN" ] && $OLLAMA_BIN list >/dev/null 2>&1; then
          for model in $($OLLAMA_BIN list | ${pkgs.coreutils}/bin/tail -n +2 | ${pkgs.gawk}/bin/awk '{print $1}'); do
            if [ -n "$model" ]; then
              # Check if model already has 32k context to remain completely idempotent and fast
              if ! $OLLAMA_BIN show "$model" --modelfile 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q "num_ctx 32768"; then
                echo "Ollama: applying 32k context patch to $model..."
                printf "FROM %s\nPARAMETER num_ctx 32768\n" "$model" | $OLLAMA_BIN create "$model" -f /dev/stdin 2>/dev/null || true
              fi
            fi
          done
        fi
      '';
    };
}
