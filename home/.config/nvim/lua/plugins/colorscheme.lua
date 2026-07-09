return {
  {
    'rose-pine/neovim',
    name = 'rose-pine',  -- plugin repo is 'neovim'; alias so :colorscheme rose-pine works
    lazy = false,     -- load during startup
    priority = 1000,  -- load before other plugins so the UI is themed immediately
    config = function()
      vim.cmd.colorscheme('rose-pine-moon')
    end,
  },
}
