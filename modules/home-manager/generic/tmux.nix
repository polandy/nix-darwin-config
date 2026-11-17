{ pkgs, ... }:
let
  copyCommand = if pkgs.stdenv.hostPlatform.isDarwin then "pbcopy" else "wl-copy";
in
{
  programs.tmux = {
    enable = true;
    # C-a as prefix2 set in extraConfig
    shortcut = "b";
    mouse = true;
    keyMode = "vi";
    terminal = "tmux-256color";
    escapeTime = 0;
    baseIndex = 1;
    extraConfig = ''
      set -ag terminal-overrides ",xterm-256color:RGB"

      set-option -g prefix2 C-a
      bind-key C-a send-prefix -2

      # C-/ sends C-_ (\x1f)
      bind-key -n C-/ send-keys "\x1f"

      set-option -g repeat-time 250
      setw -g xterm-keys on
      set -g renumber-windows on

      bind-key -r h select-pane -L
      bind-key -r j select-pane -D
      bind-key -r k select-pane -U
      bind-key -r l select-pane -R

      bind-key -r H resize-pane -L 5
      bind-key -r J resize-pane -D 5
      bind-key -r K resize-pane -U 5
      bind-key -r L resize-pane -R 5

      bind-key -r r select-layout even-horizontal
      bind-key -r R select-layout even-vertical

      bind-key -r b split-window -h
      bind-key -r v split-window -v

      bind-key -r p select-window -t :-
      bind-key -r n select-window -t :+

      bind-key -r s choose-session
      bind-key < command-prompt -I "#S" { rename-session '%%' ; display-message "Renamed to: #S" }

      bind e set -g synchronize-panes

      bind r source-file ~/.config/tmux/tmux.conf \; display-message "Config reloaded!"

      bind / command-prompt "split-window 'exec man %%'"
      bind '~' split-window "exec htop"

      set -g monitor-activity on
      set -g visual-activity off
      set -g activity-action other
      set -g visual-bell off
      set -g bell-action other

      bind-key -T copy-mode-vi v      send-keys -X begin-selection
      bind-key -T copy-mode-vi C-v    send-keys -X rectangle-toggle
      bind-key -T copy-mode-vi y      send-keys -X copy-pipe-and-cancel "${copyCommand}"
      bind-key -T copy-mode-vi Escape send-keys -X cancel
      bind-key -T copy-mode-vi H      send-keys -X start-of-line
      bind-key -T copy-mode-vi L      send-keys -X end-of-line

      set -g pane-border-style        fg=colour238
      set -g pane-active-border-style fg=colour31
      set -g pane-border-lines        single

      set -g status-position   top
      set -g status-keys       vi
      set -g status-interval   5

      set -g status-style       bg=colour235,fg=colour252
      set -g status-left-length  40
      set -g status-right-length 40
      set -g status-justify      centre

      set -g status-left  '#[fg=colour31,bold] #S #[fg=colour238]│#[default] '
      set -g status-right ' #[fg=colour238]│#[fg=colour252] %d.%m.%Y #[fg=colour75,bold]%H:%M #[default]'

      setw -g window-status-style          bg=colour235,fg=colour244
      setw -g window-status-format         ' #I:#W#F '
      setw -g window-status-current-style  bg=colour238,fg=colour75,bold
      setw -g window-status-current-format ' #I:#W#F '
      setw -g window-status-activity-style bg=colour235,fg=colour208,bold

      set -g @resurrect-capture-pane-contents 'on'
      set -g @resurrect-processes '"~claude" nvim vim htop'

      set -g @continuum-restore 'on'
      set -g @continuum-save-interval '15'

      # Not via programs.tmux.plugins: continuum hooks into
      # status-right and must load after it
      run-shell ${pkgs.tmuxPlugins.resurrect.rtp}
      run-shell ${pkgs.tmuxPlugins.continuum.rtp}
    '';
  };
}
