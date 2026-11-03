{ ... }: {
  # beets itself is installed via metapac; library.db and state.pickle stay in ~/.config/beets
  xdg.configFile."beets/config.yaml".source = ./config.yaml;
}
