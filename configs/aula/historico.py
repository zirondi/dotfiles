# Kitty watcher of the classroom terminal (configs/aula/kitty.conf): feeds the
# side panel (configs/aula/bin/aula-historico) with two files:
#   AULA_HISTORICO        every command run, with its tab label, and failures
#   AULA_HISTORICO.agora  the line recalled with Up/Down, until it runs
# The commands come from the OSC 133 marks of configs/aula/bashrc and the
# label, color and recalled line from its user vars, so commands typed over
# ssh or inside a container show up too.
import os
import time
from typing import Any

from kitty.boss import Boss
from kitty.window import Window

ARQUIVO = os.environ.get('AULA_HISTORICO', '')
AGORA = ARQUIVO + '.agora' if ARQUIVO else ''

DIM, BOLD, RED, RESET = '\x1b[2m', '\x1b[1m', '\x1b[31m', '\x1b[0m'

# Same table as __aula_status_texto in configs/aula/bashrc
SIGNIFICADO = {
    1: 'erro',
    2: 'uso errado',
    126: 'sem permissão',
    127: 'não encontrado',
    130: 'cancelado (Ctrl+C)',
    137: 'morto (SIGKILL)',
    141: 'pipe fechado',
    143: 'encerrado (SIGTERM)',
    148: 'pausado (Ctrl+Z)',
}


def significado(status: int) -> str:
    if status in SIGNIFICADO:
        return SIGNIFICADO[status]
    return f'sinal {status - 128}' if status > 128 else 'erro'


def rotulo(window: Window) -> str:
    """The tab label in its color (bashrc sends both), or a blank column."""
    letra = window.user_vars.get('aula_rotulo', '')
    cor = window.user_vars.get('aula_cor', '')
    if not letra:
        return ' '
    if len(cor) == 6:
        r, g, b = (int(cor[i:i + 2], 16) for i in (0, 2, 4))
        return f'{BOLD}\x1b[38;2;{r};{g};{b}m{letra}{RESET}'
    return f'{BOLD}{letra}{RESET}'


def escreve(caminho: str, texto: str, modo: str = 'a') -> None:
    with open(caminho, modo, encoding='utf-8') as f:
        f.write(texto)


def on_cmd_startstop(boss: Boss, window: Window, data: dict[str, Any]) -> None:
    cmd = data.get('cmdline', '').strip()
    if not ARQUIVO or not cmd:
        return
    if data['is_start']:
        escreve(ARQUIVO, f"{DIM}{time.strftime('%H:%M')}{RESET} {rotulo(window)} {cmd}\n")
        escreve(AGORA, '', 'w')
    elif data['exit_status']:
        # Short form: the panel is about 26 columns at 22 pt on a 1080p screen,
        # so the key in parentheses stays in the prompt only
        status = data['exit_status']
        escreve(ARQUIVO, f"{RED}  ↳ {status} {significado(status).split(' (')[0]}{RESET}\n")


def on_set_user_var(boss: Boss, window: Window, data: dict[str, Any]) -> None:
    if not AGORA or data['key'] != 'aula_linha':
        return
    linha = (data['value'] or '').strip()
    escreve(AGORA, f"{rotulo(window)} ↑ {linha}\n" if linha else '', 'w')
