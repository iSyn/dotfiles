return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',  -- rewrite; master is frozen and breaks on nvim 0.12
    lazy = false,  -- the plugin does not support lazy-loading
    build = ':TSUpdate',  -- rebuild installed parsers when the plugin updates
    config = function()
      -- install these up front; anything else installs on demand (see autocmd)
      require('nvim-treesitter').install {
        'tsx', 'javascript', 'typescript', 'lua', 'vim', 'vimdoc', 'bash', 'json', 'yaml', 'markdown', 'markdown_inline',
      }

      -- the main branch enables nothing by itself: highlighting and indentation
      -- are switched on per buffer through core vim.treesitter
      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('treesitter_start', {}),
        callback = function(args)
          local lang = vim.treesitter.language.get_lang(args.match)
          if not lang then return end

          local function start()
            vim.treesitter.start(args.buf, lang)
            vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end

          if pcall(start) then return end

          -- parser missing: build it, then retry (the old auto_install = true)
          local ts = require('nvim-treesitter')
          if not vim.tbl_contains(ts.get_available(), lang) then return end
          ts.install(lang):await(function()
            if vim.api.nvim_buf_is_valid(args.buf) then pcall(start) end
          end)
        end,
      })
    end,
  },
}
