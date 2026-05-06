{ ... }:
{
	programs.fish = {
		enable = true;

		shellInit = ''
			# Universal variables
			set -U MANROFFOPT "-c"
			set -U MANPAGER "sh -c 'col -bx | bat -l man -p'"
			set -U __done_min_cmd_duration 10000
			set -U __done_notification_urgency_level low
		'';

		interactiveShellInit = ''
			fish_add_path ~/.local/bin ~/.cargo/bin ~/.dotnet/tools

			# Bindings for !! and !$
			if [ "$fish_key_bindings" = fish_vi_key_bindings ]
				bind -Minsert ! __history_previous_command
				bind -Minsert '$' __history_previous_command_arguments
			else
				bind ! __history_previous_command
				bind '$' __history_previous_command_arguments
			end
		'';

		functions = {
			fish_greeting = ''
				fastfetch
			'';
			fish_prompt = ''
				set_color e18384; echo -n (whoami)
				set_color cyan; echo -n '@'
				set_color e18384; echo -n (hostnamectl hostname)
				set_color cyan; echo -n '>'(prompt_pwd)' $ '
			'';
			history = ''
				builtin history --show-time='%F %T '
			'';
			backup = ''
				cp $argv[1] $argv[1].bak
			'';
			copy = ''
				set count (count $argv | tr -d \n)
				if test "$count" = 2; and test -d "$argv[1]"
						set from (echo $argv[1] | trim-right /)
						set to (echo $argv[2])
						command cp -r $from $to
				else
						command cp $argv
				end
			'';
			__history_previous_command = ''
				switch (commandline -t)
				case "!"
					commandline -t $history[1]; commandline -f repaint
				case "*"
					commandline -i !
				end
			'';
			__history_previous_command_arguments = ''
				switch (commandline -t)
				case "!"
					commandline -t ""
					commandline -f history-token-search-backward
				case "*"
					commandline -i '$'
				end
			'';
		};
	};
}