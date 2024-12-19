link-nvim:
	rm -rf ~/.config/nvim
	ln -s $(PWD)/nvim ~/.config/nvim

link-wezterm:
	rm ~/.wezterm.lua
	ln -s $(PWD)/wezterm ~/.config/wezterm

link-zsh:
	rm ~/.zshrc
	ln -s $(PWD)/zsh/.zshrc ~/.zshrc
	rm ~/.zprofile
	ln -s $(PWD)/zsh/.zsh_profile ~/.zprofile
