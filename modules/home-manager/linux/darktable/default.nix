{ ... }: {
  # darktable itself is installed via metapac; darktablerc, shortcutsrc and the
  # library databases stay as writable state in ~/.config/darktable
  xdg.configFile = {
    "darktable/luarc".source = ./luarc;
    "darktable/lua/rate_group.lua".source = ./lua/rate_group.lua;
    "darktable/user.css".source = ./user.css;
    # exported shortcuts, import manually via preferences > shortcuts
    "darktable.shortcuts".source = ./darktable.shortcuts;
  };
}
