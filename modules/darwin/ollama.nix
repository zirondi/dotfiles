{ config, lib, ... }:

{
  # --- Ollama Local LLM Inference ---
  # Runs as a launchd user agent so it starts automatically on login.
  # Listens on 0.0.0.0:11434 to be accessible via Tailscale mesh VPN.
  # SECURITY: Only exposed within the Tailscale network, not public internet.

  launchd.user.agents.ollama = {
    serviceConfig = {
      Label = "com.zirondi.ollama";
      ProgramArguments = [ "/opt/homebrew/bin/ollama" "serve" ];
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
}
