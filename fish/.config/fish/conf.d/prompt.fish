# basic colors
set -g hydro_color_pwd blue
set -g hydro_color_prompt purple
set -g hydro_color_duration yellow
set -g hydro_color_git brblack

# override colors for git symbols
set -g hydro_color_git_dirty magenta
set -g hydro_color_git_ahead cyan
set -g hydro_color_git_behind cyan
set -g hydro_symbol_git_ahead "$_hydro_color_git_ahead↑$hydro_color_normal"
set -g hydro_symbol_git_behind "$_hydro_color_git_behind↓$hydro_color_normal"
set -g hydro_symbol_git_dirty "$_hydro_color_git_dirty*$hydro_color_normal"

set -g hydro_multiline true
