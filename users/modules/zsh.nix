{ config, ... }:
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    defaultKeymap = "viins";
    autosuggestion = {
      enable = true;

      highlight = "fg=#666666";
      strategy = [ "history" "completion" ];
    };

    syntaxHighlighting = {
      enable = true;

      highlighters = [
        "main"
        "brackets"
        "pattern"
        "cursor"
      ];

      styles = {
        alias = "fg=green,bold";
        builtin = "fg=green,bold";
        command = "fg=green,bold";
        unknown-token = "fg=red,bold";
        reserved-word = "fg=yellow";
      };
    };

    initContent = ''
      autoload -Uz colors && colors
      export MANROFFOPT="-c"
      PROMPT='%F{#e18384}%n%F{cyan}@%F{#e18384}%m%F{cyan}>%~ $ %f'
      path=(
        $path
      )

      history() {
        builtin history -i -f
        fc -l -t '%F %T' "$@"
      }

      TRAPINT() {
				zle && zle kill-whole-line
      }
    '';

    history = {
      size = 100000;
      save = 100000;
      path = "$HOME/.zsh_history";
      ignoreDups = true;
      share = true;
    };

    historySubstringSearch = {
      enable = true;
      searchUpKey = "^[[A";
      searchDownKey = "^[[B";
    };
  };
}
