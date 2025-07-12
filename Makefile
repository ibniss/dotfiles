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
	ln -s $(PWD)/zsh/.zshrc ~/.zshrc
	rm -f ~/.zprofile
	ln -s $(PWD)/zsh/.zsh_profile ~/.zprofile

link-mise:
	rm -f ~/.config/mise/config.toml
	mkdir -p ~/.config/mise
	ln -s $(PWD)/mise/config.toml ~/.config/mise/config.toml

link-keyd:
	sudo cp $(PWD)/keyd/default.conf  /etc/keyd/default.conf
