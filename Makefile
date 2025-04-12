link-nvim:
	rm -rf ~/.config/nvim
	ln -s $(PWD)/nvim ~/.config/nvim

link-wezterm:
	rm -f ~/.wezterm.lua
	ln -s $(PWD)/wezterm ~/.config/wezterm
	rm -f ~/wezterm.sh
	ln -s $(PWD)/wezterm/wezterm.sh ~/wezterm.sh

link-zsh:
	rm -f ~/.zshrc
	ln -s $(PWD)/zsh/.zshrc.linux ~/.zshrc
	rm -f ~/.zprofile
	ln -s $(PWD)/zsh/.zsh_profile ~/.zprofile

link-keyd:
	sudo cp $(PWD)/keyd/default.conf  /etc/keyd/default.conf
