return {
  {
    'saghen/blink.cmp',
    version = '*',  -- release tag; ships a prebuilt fuzzy-matcher binary
    event = 'InsertEnter',
    opts = {
      keymap = { preset = 'default' },  -- <C-space> open, <C-y> accept, <C-n>/<C-p> cycle
      appearance = { nerd_font_variant = 'normal' },
      completion = {
        documentation = { auto_show = true },  -- show docs popup alongside the menu
      },
      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
      },
      fuzzy = { implementation = 'prefer_rust_with_warning' },  -- fall back to lua if binary missing
    },
  },
}
