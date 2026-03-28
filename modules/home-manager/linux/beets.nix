{ config, lib, ... }:

{
  options.myModules.beets.enable = lib.mkEnableOption "beets music manager";

  config = lib.mkIf config.myModules.beets.enable {
    programs.beets = {
      enable = true;
      settings = {
        replace = {
          "[\\\\//]" = "_";
          "^\\." = "_";
          "[\\x00-\\x1f]" = "_";
          "[<>:\"\\?\\*\\|]" = "_";
          "\\.$" = "_";
          "\\s+$" = "";
          "^\\s+" = "";
          "^-" = "_";
          "\\ " = "_";
        };
        import = {
          write = true;
          copy = false;
          move = true;
        };
        format_item = "$artist - $year - $album - $title";
        format_album = "$albumartist - $year - $album";
        paths = {
          default = "Music/%the{$albumartist}/$year-$album%aunique{}/$track $title";
          "albumtype:\"Audio Drama\"" = "Audio_Dramas/%the{$albumartist}/$year-$album%aunique{}/$track $title";
          "albumtype:\"compilation\"" = "Compilations/$year-$album%aunique{}/$track $artist $title";
          "albumtype:\"soundtrack\"" = "soundtrack/$year-$album%aunique{}/$track $artist $title";
        };
        plugins = [ "fetchart" "embedart" "ftintitle" "lyrics" "types" "lastgenre" "badfiles" "replaygain" "the" "missing" "rewrite" ];
        fetchart.auto = true;
        embedart = {
          auto = true;
          remove_art_file = true;
        };
        ftintitle.auto = true;
        lyrics.auto = true;
        types = {
          ripped = "bool";
          radioplay = "bool";
        };
        replaygain = {
          auto = false;
          backend = "gstreamer";
        };
        rewrite = {
          "artist JAY-Z.*Linkin Park" = "Linkin Park";
          "artist OVERWERK*" = "OVERWERK";
        };
      };
    };
  };
}
