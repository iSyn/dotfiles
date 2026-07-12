{ config, pkgs, ... }:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
in

{
  home.username = "synclairwang";
  home.homeDirectory = "/Users/synclairwang";
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    # cli i use constantly
    ripgrep   # fast search
    fd        # fast find
    fzf       # fuzzy finder
    jq        # json on the command line
    lazygit
    neovim
    gh        # github cli
    tree-sitter # CLI required by nvim-treesitter (main branch) to build parsers
    nodejs_24 # node + npm (current active LTS)
    pnpm      # fast, disk-efficient package manager (used by work repos)
    nerd-fonts.hack

    # language servers (consumed by nvim-lspconfig; installed via nix so
    # `./rebuild` gives the identical toolchain on every machine)
    lua-language-server            # lua_ls  - neovim config
    nixd                           # nixd    - nix files (flake/home/configuration)
    typescript                     # tsc     - required by ts_ls for standalone files
    typescript-language-server     # ts_ls   - typescript / javascript / jsx / tsx
    bash-language-server           # bashls  - shell scripts
    vscode-langservers-extracted   # jsonls, cssls, html, eslint (bundled)
    yaml-language-server           # yamlls  - yaml
    tailwindcss-language-server    # tailwindcss - class autocomplete
    emmet-language-server          # emmet_language_server - jsx/html expansion
    # formatters (consumed by conform.nvim for format-on-save)
    prettierd                      # js/ts/jsx/tsx/json/css/html/yaml/markdown
    stylua                         # lua
    nixfmt-rfc-style               # nix (provides the `nixfmt` binary)
  ];

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;      # ghost text from history
    syntaxHighlighting.enable = true;  # commands turn green when valid
    initContent = ''
      bindkey '^f' autosuggest-accept
    '';
    shellAliases = {
      cc = "claude"; 
      co = "codex --full-auto";
      lg = "lazygit";
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

  # Edit-in-place: the real file stays in my repo, ~/.config just points at it.
  home.file.".config/wezterm".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/wezterm";
  home.file.".config/nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/nvim";
  home.file.".config/herdr".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/herdr";
  home.file.".claude/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/settings.json";
  home.file.".claude/skills".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/skills";

  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".codex/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".config/opencode/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  
  programs.home-manager.enable = true;
}
