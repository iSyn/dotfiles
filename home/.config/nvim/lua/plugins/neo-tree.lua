return {
  {
    'nvim-neo-tree/neo-tree.nvim',
    branch = 'v3.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons',  -- file icons
      'MunifTanjim/nui.nvim',
    },
    lazy = false,  -- load at startup so neo-tree (not netrw) owns directory buffers
    keys = {
      { '<leader>e', '<cmd>Neotree toggle<cr>', desc = 'File Browser' },
    },
    opts = {
      close_if_last_window = true,  -- don't leave a lone tree window when closing the last file
      filesystem = {
        hijack_netrw_behavior = 'open_default',    -- take over directory buffers, disable netrw
        follow_current_file = { enabled = true },  -- highlight the file you're editing in the tree
        use_libuv_file_watcher = true,             -- auto-refresh on external file changes
        filtered_items = {
          visible = true,        -- show hidden/gitignored items (dimmed) instead of omitting them
          hide_dotfiles = false, -- show dotfiles
          hide_gitignored = false,
        },
      },
    },
  },
}
