require('lualine').setup({
	theme = 'palenight',
	sections = {
		lualine_a = { 'mode' },
		lualine_b = { '%{FugitiveStatusline()}', 'diff', 'diagnostics' },
		lualine_c = { 'filename' },
		lualine_x = { 'fileformat', 'filetype' },
		lualine_y = { 'progress' },
		lualine_z = { 'location' }
	},
})
