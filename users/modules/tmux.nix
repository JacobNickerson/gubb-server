{ ... }:
{
	programs.tmux = {
		enable = true;

		historyLimit = 10000;
		escapeTime = 0;
		keyMode = "vi";
		mouse = true;
		terminal = "tmux-256color";
		prefix = "C-q"; 
		extraConfig = ''
			# Switch panes using alt, Vi style
			bind -n M-h select-pane -L
			bind -n M-l select-pane -R
			bind -n M-k select-pane -U
			bind -n M-j select-pane -D

			bind | split-window -h
			bind - split-window -v
			unbind '"'
			unbind '%'

			set-option -g destroy-unattached on

			# Pane borders
			set -g pane-border-style 'fg=colour4'
			set -g pane-active-border-style 'fg=colour5'

			# Status bar
			set -g status-position bottom
			set -g status-justify left
			set -g status-style 'fg=colour4'
			# gotta do some wacky quotes for nix
			set -g status-left ''''''
			set -g status-right '%Y-%m-%d %H:%M '
			set -g status-right-length 50
			set -g status-left-length 10
		'';
	};
}