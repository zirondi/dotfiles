# Tab titles of the classroom kitty (kitty.conf: tab_title_template "{custom}").
# The label letter of each tab is drawn in its color; configs/aula/bashrc
# sends both as user vars (aula_rotulo, aula_cor), so the color table lives
# only there.
from typing import Any

from kitty.fast_data_types import get_boss


def draw_title(data: dict[str, Any]) -> str:
    title = data['title']
    tab = get_boss().tab_for_id(data['tab_id'])
    if tab is None:
        return title
    # The shell's window, not the history panel next to it
    cor = ''
    for window in tab:
        cor = window.user_vars.get('aula_cor', '')
        if cor:
            break
    if len(cor) != 6:
        return title
    fmt = data['fmt']
    letra, espaco, resto = title.partition(' ')
    return f'{fmt.bold}{getattr(fmt.fg, "_" + cor)}{letra}{fmt.fg.tab}{fmt.nobold}{espaco}{resto}'
