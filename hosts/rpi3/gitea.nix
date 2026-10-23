{ config, pkgs, ... }:

# Gitea as a read-only mirror of GitHub: GitHub stays where pushes go, and
# Gitea pulls every personal and organisation repository on a schedule
# (scripts/gitea-mirror.sh creates the mirrors). Reachable over the tailnet
# only, through the Pi's Traefik, like the other *.rpi3 names.
#
# The admin user and its API token are created by hand once, with the CLI
# installed below (scratch/wizards/sprint.sh, Sunday).
let
  domain = "gitea.rpi3.leazirondi.com.br";
  port = 3000;
in
{
  services.gitea = {
    enable = true;
    appName = "Gitea (espelho do GitHub)";
    database.type = "sqlite3";
    settings = {
      server = {
        ROOT_URL = "https://${domain}/";
        HTTP_ADDR = "127.0.0.1";
        HTTP_PORT = port;
        # Mirrors only: nobody pushes here, so there is no SSH endpoint
        DISABLE_SSH = true;
      };
      service.DISABLE_REGISTRATION = true;
      session.COOKIE_SECURE = true;
      mirror = {
        ENABLED = true;
        DEFAULT_INTERVAL = "8h";
        MIN_INTERVAL = "1h";
      };
      log.LEVEL = "Warn";
    };
  };

  # `gitea admin ...` for the one-time admin setup; run it as the gitea user
  # with --config /var/lib/gitea/custom/conf/app.ini
  environment.systemPackages = [ config.services.gitea.package ];

  services.traefik.dynamicConfigOptions.http = {
    routers.gitea = {
      rule = "Host(`${domain}`)";
      entryPoints = [ "websecure" ];
      service = "gitea";
    };
    services.gitea.loadBalancer.servers = [ { url = "http://127.0.0.1:${toString port}"; } ];
  };

  # Repositories are plain files under the state directory; the live SQLite
  # file is skipped and copied consistently into the dumps instead.
  backup = {
    paths = [ config.services.gitea.stateDir ];
    exclude = [ "${config.services.gitea.stateDir}/data/gitea.db*" ];
    prepare = ''
      ${pkgs.sqlite}/bin/sqlite3 ${config.services.gitea.stateDir}/data/gitea.db ".backup '$DUMPS/gitea.db'"
    '';
  };
}
