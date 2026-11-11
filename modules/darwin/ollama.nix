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
        # Default context for requests that set none (OLLAMA_NUM_CTX is not an Ollama variable)
        OLLAMA_CONTEXT_LENGTH = "32768";
        # 16 GB of unified memory: one model and one request at a time, kept loaded between
        # OpenCode turns, with an 8-bit KV cache (which needs flash attention)
        OLLAMA_FLASH_ATTENTION = "1";
        OLLAMA_KV_CACHE_TYPE = "q8_0";
        OLLAMA_NUM_PARALLEL = "1";
        OLLAMA_MAX_LOADED_MODELS = "1";
        OLLAMA_KEEP_ALIVE = "30m";
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
      # Raise every local model to at least a 32k context for OpenCode, and create the
      # 64k alias of the main model. Models that already carry a larger num_ctx (the alias)
      # are left alone; pulling a model stays manual.
      home.activation.buildOllamaModels = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        OLLAMA_BIN="/opt/homebrew/bin/ollama"
        if [ -x "$OLLAMA_BIN" ] && $OLLAMA_BIN list >/dev/null 2>&1; then
          for model in $($OLLAMA_BIN list | ${pkgs.coreutils}/bin/tail -n +2 | ${pkgs.gawk}/bin/awk '{print $1}'); do
            if [ -n "$model" ]; then
              ctx=$($OLLAMA_BIN show "$model" --modelfile 2>/dev/null | ${pkgs.gawk}/bin/awk '$1 == "PARAMETER" && $2 == "num_ctx" {n = $3} END {print n + 0}')
              if [ "$ctx" -lt 32768 ]; then
                echo "Ollama: applying 32k context patch to $model..."
                printf "FROM %s\nPARAMETER num_ctx 32768\n" "$model" | $OLLAMA_BIN create "$model" -f /dev/stdin 2>/dev/null || true
              fi
            fi
          done

          # OpenCode's main model (configs/opencode/opencode.json) needs a 64k context
          if $OLLAMA_BIN show qwen3.5:9b >/dev/null 2>&1 && ! $OLLAMA_BIN show qwen3.5-64k >/dev/null 2>&1; then
            echo "Ollama: creating qwen3.5-64k (qwen3.5:9b with a 64k context)..."
            printf "FROM qwen3.5:9b\nPARAMETER num_ctx 65536\n" | $OLLAMA_BIN create qwen3.5-64k -f /dev/stdin 2>/dev/null || true
          fi
        fi
      '';
    };
}
