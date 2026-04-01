import os

os.chdir(os.path.dirname(__file__))

with open("flag.txt") as f:
    data = f.read().strip()

import lark

parser = lark.Lark(
    """
    start: (text|ansi)*
    text: /[!-~\s]+/ -> text
    ansi: "\x1b[" (cursor_control | erace_function | screen_mode | color_control)

    cursor_control: NUMBER "A" -> move_up
        | NUMBER "B" -> move_down
        | NUMBER "C" -> move_right
        | NUMBER "D" -> move_left

    erace_function: "K" -> erase_line_right

    screen_mode: "?1049h" -> enable_alternate_screen
      | "?1049l" -> disable_alternate_screen
    
    color_control: (NUMBER ";")* NUMBER "m" -> color_control
      | "m" -> reset_color
    NUMBER: /[0-9]+/
    """
)

tree = parser.parse(data)

pass
