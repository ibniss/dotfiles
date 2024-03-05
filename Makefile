link-nvim:
	rm -rf ~/.config/nvim
	ln -s $(PWD)/nvim ~/.config/nvim

link-wezterm:
	rm ~/.wezterm.lua
	ln -s $(PWD)/wezterm ~/.config/wezterm
