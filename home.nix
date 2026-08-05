{
  config,
  pkgs,
  lib,
  ...
}:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
in

{
  home.username = "synclairwang";
  home.homeDirectory = "/Users/synclairwang";
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    # cli i use constantly
    ripgrep # fast search
    fd # fast find
    fzf # fuzzy finder
    jq # json on the command line
    lazygit
    neovim
    gh # github cli
    tree-sitter # CLI required by nvim-treesitter (main branch) to build parsers
    nodejs_24 # node + npm (current active LTS)
    pnpm # fast, disk-efficient package manager (used by work repos)
    nerd-fonts.hack

    # language servers (consumed by nvim-lspconfig; installed via nix so
    # `./rebuild` gives the identical toolchain on every machine)
    lua-language-server # lua_ls  - neovim config
    nixd # nixd    - nix files (flake/home/configuration)
    typescript # tsc     - required by ts_ls for standalone files
    typescript-language-server # ts_ls   - typescript / javascript / jsx / tsx
    bash-language-server # bashls  - shell scripts
    vscode-langservers-extracted # jsonls, cssls, html, eslint (bundled)
    yaml-language-server # yamlls  - yaml
    tailwindcss-language-server # tailwindcss - class autocomplete
    emmet-language-server # emmet_language_server - jsx/html expansion
    # formatters (consumed by conform.nvim for format-on-save)
    prettierd # js/ts/jsx/tsx/json/css/html/yaml/markdown
    stylua # lua
    nixfmt-rfc-style # nix (provides the `nixfmt` binary)
  ];

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true; # ghost text from history
    syntaxHighlighting.enable = true; # commands turn green when valid
    initContent = ''
      bindkey '^f' autosuggest-accept

      # Prefer the Nix-managed toolchain over Homebrew on PATH. Homebrew's node
      # exists only as an `opencode` dependency and would otherwise shadow our
      # declared Nix node (see home.packages: nodejs_24) for `node`/`npm`.
      export PATH="/etc/profiles/per-user/${config.home.username}/bin:$PATH"
    '';
    shellAliases = {
      cc = "claude";
      oc = "opencode --auto";
      lg = "lazygit";
      gs = "git switch";
      ga = "git add";
      gc = "git commit";
      gp = "git pull";
      gP = "git push";
    };
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$line_break$character";
      character = {
        success_symbol = "[❯](purple)";
        error_symbol = "[❯](red)";
      };
      cmd_duration.format = "[$duration]($style) ";
    };
  };

  fonts.fontconfig.enable = true;
  home.sessionVariables.EDITOR = "nvim";

  home.activation.handySettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings_dir="$HOME/Library/Application Support/com.pais.handy"
    settings_file="$settings_dir/settings_store.json"
    managed_settings="${dotfiles}/home/.config/handy/managed-settings.json"

    if [[ -n "''${DRY_RUN_CMD:-}" ]]; then
      echo "Would merge managed Handy preferences into $settings_file"
    else
      umask 077
      mkdir -p "$settings_dir"
      if [[ ! -f "$settings_file" ]]; then
        printf '{"settings":{}}\n' > "$settings_file"
      fi

      tmp_file="$settings_file.tmp"
      ${pkgs.jq}/bin/jq --slurpfile managed "$managed_settings" \
        '.settings = ((.settings // {}) * $managed[0])' \
        "$settings_file" > "$tmp_file"
      mv "$tmp_file" "$settings_file"
    fi
  '';

  # Edit-in-place: the real file stays in my repo, ~/.config just points at it.
  home.file.".config/wezterm".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/wezterm";
  home.file.".config/nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/nvim";
  home.file.".config/herdr".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/herdr";
  home.file.".claude/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/settings.json";
  # Vendor-neutral skills hub (opencode, codex, cursor, gemini read it natively).
  # Claude Code is the holdout that only reads ~/.claude/skills, so it gets a
  # compat symlink to the same bundle.
  home.file.".agents/skills".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.agents/skills";
  home.file.".claude/skills".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.agents/skills";

  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".codex/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".config/opencode/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".config/opencode/tui.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/opencode/tui.json";

  programs.home-manager.enable = true;
}
