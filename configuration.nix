{ ... }:

{
  # Determinate already manages the Nix daemon, so nix-darwin shouldn't
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin";

  system.primaryUser = "synclairwang";
  users.users.synclairwang = {
    home = "/Users/synclairwang";
  };
  system.stateVersion = 6;

  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      KeyRepeat = 1;              # fast key repeat
      InitialKeyRepeat = 10;      # short delay before repeat
      _HIHideMenuBar = true;      # auto-hide the menu bar
      AppleShowAllExtensions = true;
    };
    dock.autohide = true;
    finder.FXPreferredViewStyle = "Nlsv";  # list view by default
    finder.CreateDesktop = false;          # clean desktop
    finder.AppleShowAllFiles = true;       # show hidden files
    trackpad.Clicking = true;              # tap to click
  };

  nix-homebrew = {
    enable = true;
    user = "synclairwang";
    autoMigrate = true;  # take over the existing /opt/homebrew install, keeping packages
  };
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";  # remove anything not listed here
    onActivation.autoUpdate = true;
    onActivation.extraFlags = [ "--force" ];
    brews = [
      "herdr"
    ];
    casks = [
      "wezterm"
      "claude-code"
      "codex"
      "google-cloud-sdk"
      "wispr-flow"
    ];
  };
}
