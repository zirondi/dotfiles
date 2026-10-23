{
  config,
  lib,
  pkgs,
  ...
}:

# Cloudflare Tunnel connector of the Mac (the remote-access tunnel). The
# tunnel itself, and any public hostname routed through it, is configured in
# the Cloudflare dashboard; this only keeps the connector running. The token
# comes from the host's sops file as `cloudflared_token`, owned by the
# primary user, and is read from a file so it never shows in `ps`.
let
  cfg = config.services.cloudflaredTunnel;
  user = config.system.primaryUser;
  home = config.users.users.${user}.home;
in
{
  options.services.cloudflaredTunnel.enable = lib.mkEnableOption "the Cloudflare Tunnel connector";

  config = lib.mkIf cfg.enable {
    sops.secrets.cloudflared_token.owner = user;

    launchd.user.agents.cloudflared.serviceConfig = {
      Label = "com.zirondi.cloudflared";
      ProgramArguments = [
        "${pkgs.cloudflared}/bin/cloudflared"
        "tunnel"
        "--no-autoupdate"
        "run"
        "--token-file"
        config.sops.secrets.cloudflared_token.path
      ];
      RunAtLoad = true;
      KeepAlive = true;
      # Back off instead of restarting every few seconds when the token is bad
      ThrottleInterval = 60;
      StandardOutPath = "${home}/Library/Logs/cloudflared.log";
      StandardErrorPath = "${home}/Library/Logs/cloudflared.log";
    };
  };
}
