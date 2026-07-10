return {
  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    opts = {
      formatters_by_ft = {
        lua = { 'stylua' },
        nix = { 'nixfmt' },
        javascript = { 'prettierd' },
        javascriptreact = { 'prettierd' },
        typescript = { 'prettierd' },
        typescriptreact = { 'prettierd' },
        json = { 'prettierd' },
        jsonc = { 'prettierd' },
        yaml = { 'prettierd' },
        css = { 'prettierd' },
        html = { 'prettierd' },
        markdown = { 'prettierd' },
      },
      -- format on save, falling back to the LSP formatter if no formatter is configured
      format_on_save = {
        timeout_ms = 2000,
        lsp_format = 'fallback',
      },
    },
  },
}
