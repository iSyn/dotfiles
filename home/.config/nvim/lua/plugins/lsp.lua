return {
  {
    'neovim/nvim-lspconfig',
    dependencies = { 'saghen/blink.cmp' },  -- for completion capabilities
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      -- advertise blink.cmp's completion capabilities to every server
      local ok, blink = pcall(require, 'blink.cmp')
      if ok then
        vim.lsp.config('*', { capabilities = blink.get_lsp_capabilities() })
      end

      -- lua_ls: teach it the `vim` global so editing nvim config is warning-free
      vim.lsp.config('lua_ls', {
        settings = {
          Lua = {
            diagnostics = { globals = { 'vim' } },
            workspace = { checkThirdParty = false },
          },
        },
      })

      -- turn the servers on; nvim-lspconfig ships each server's default config,
      -- and vim.lsp.enable (neovim 0.11+) wires them up natively
      vim.lsp.enable({
        'lua_ls',
        'nixd',
        'ts_ls',
        'bashls',
        'jsonls',
        'yamlls',
        'cssls',
        'html',
        'eslint',
        'tailwindcss',
        'emmet_language_server',
      })

      -- diagnostics: inline text + signs, rounded float on hover
      vim.diagnostic.config({
        virtual_text = true,
        severity_sort = true,
        float = { border = 'rounded' },
      })

      -- buffer-local keymaps, set only once a server actually attaches
      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(ev)
          local map = function(keys, fn, desc)
            vim.keymap.set('n', keys, fn, { buffer = ev.buf, desc = 'LSP: ' .. desc })
          end
          -- gd is already mapped to Snacks.picker.lsp_definitions in navigation.lua
          map('gr', vim.lsp.buf.references, 'References')
          map('gi', vim.lsp.buf.implementation, 'Implementation')
          map('K', vim.lsp.buf.hover, 'Hover Docs')
          map('<leader>rn', vim.lsp.buf.rename, 'Rename Symbol')
          map('<leader>ca', vim.lsp.buf.code_action, 'Code Action')
          map('<leader>d', vim.diagnostic.open_float, 'Line Diagnostics')
          map('[d', function() vim.diagnostic.jump({ count = -1 }) end, 'Prev Diagnostic')
          map(']d', function() vim.diagnostic.jump({ count = 1 }) end, 'Next Diagnostic')
        end,
      })
    end,
  },
}
