# Servidor de Minecraft: boot automático e backup

Para um host Debian com `sudo`, fora do flake. O servidor roda numa sessão `screen` iniciada pelo systemd, e um timer faz backup diário com Restic no Google Drive (`gdrive:backups/minecraft`). Durante a cópia o mundo é gravado e o salvamento fica pausado (`save-off`, `save-all flush`, `save-on` no fim, mesmo se o backup falhar).

| Arquivo | Vai para |
| :--- | :--- |
| `scripts/mc-backup.sh` (raiz do repo) | `/usr/local/bin/mc-backup.sh` |
| `minecraft.service` | `/etc/systemd/system/` |
| `mc-backup.service`, `mc-backup.timer` | `/etc/systemd/system/` |
| `env.example` | `/etc/mc-backup/env` |

O token do Drive usa um client OAuth só deste servidor (`rclone-minecraft`, escopo `drive.file`): revogar ele não afeta os outros backups, e ele só enxerga o que ele mesmo criou. A senha do Restic também é própria deste servidor.

## Instalação

1. Pacotes. O `restic` do apt pode ser antigo; o `self-update` traz a versão atual (o script precisa da 0.17 ou mais nova):
   ```
   sudo apt install restic rclone screen
   sudo restic self-update
   ```
2. Copie os arquivos (de `scp` a partir do Mac, por exemplo) e ajuste os valores:
   - `/etc/mc-backup/env`: diretório do servidor, usuário e nome da sessão `screen`.
   - `minecraft.service`: `User`, `WorkingDirectory` e o script que inicia o servidor (o `start.sh` com o `java -jar ...`). O nome da sessão (`mc`) aparece três vezes.
   ```
   sudo install -m 755 mc-backup.sh /usr/local/bin/
   sudo install -d -m 700 /etc/mc-backup
   sudo install -m 600 env.example /etc/mc-backup/env
   ```
3. Token do Drive. No servidor:
   ```
   sudo rclone config --config /etc/mc-backup/rclone.conf
   ```
   Remote novo `gdrive`, tipo `drive`, client ID e secret do `rclone-minecraft`, escopo `drive.file`. Quando ele perguntar se pode usar um navegador, responda **não**: ele mostra um comando `rclone authorize "drive" "..."` para rodar no Mac, que abre o login; cole a resposta de volta no servidor. Depois: `sudo chmod 600 /etc/mc-backup/rclone.conf`.
4. Senha do Restic, gerada direto no arquivo:
   ```
   sudo sh -c 'umask 077; openssl rand -base64 36 > /etc/mc-backup/restic-password'
   ```
   Guarde uma cópia no cofre e no papel (`sudo cat /etc/mc-backup/restic-password`, no seu terminal). Sem ela o backup não é restaurável.
5. Se o servidor estiver rodando num `screen` aberto à mão, pare-o (`stop` no console). Depois:
   ```
   sudo systemctl daemon-reload
   sudo systemctl enable --now minecraft.service mc-backup.timer
   ```
6. Primeiro backup na mão, e confira:
   ```
   sudo systemctl start mc-backup.service
   journalctl -u mc-backup -n 30
   ```

## Uso

- Console do servidor: `sudo -u <usuário> screen -r mc` (sair com `Ctrl-a d`, nunca `Ctrl-c`).
- Próximo backup: `systemctl list-timers mc-backup.timer`.
- Snapshots e restore (como root, com o ambiente do arquivo):
  ```
  sudo bash -c 'set -a; . /etc/mc-backup/env; restic snapshots'
  sudo bash -c 'set -a; . /etc/mc-backup/env; restic restore latest --target /tmp/restore-mc'
  ```
  Para voltar um mundo: pare o servidor (`systemctl stop minecraft`), troque a pasta do mundo pela restaurada e inicie de novo.
