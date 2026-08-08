{ ... }:

{
  programs.mise = {
    enable = true;
    enableFishIntegration = true;
    globalConfig = {
      tools = {
        go = "1.21";
        java = "17";
        maven = "3";
        node = "22";
        usage = "latest";
      };
    };
  };
}
