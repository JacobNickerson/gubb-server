{ pkgs, ... }:
{
	programs.neovim = {
		enable = true;

		viAlias = true;
		vimAlias = true;
		plugins = with pkgs.vimPlugins; [
			pkgs.vimPlugins.nightfly
			pkgs.vimPlugins.nvim-treesitter
			pkgs.vimPlugins.lualine-nvim
		];
		initLua = ''
			vim.opt.termguicolors = true
			vim.cmd [[colorscheme nightfly]]
			vim.opt.tabstop = 2
			vim.opt.shiftwidth = 2
			vim.opt.softtabstop = 2
			vim.opt.expandtab = true
		'';
		
		# TODO: Remove if updating to 26.11
		withRuby = false;
		withPython3 = false;
	};
}