return {
  {
    'nanozuki/tabby.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },  -- filetype icons in tab labels
    event = 'VimEnter',  -- draw the tabline as soon as the UI is up
    config = function()
      vim.o.showtabline = 2  -- always show the tabline (set to 1 for only-when-multiple-tabs)
      require('tabby').setup({
        preset = 'tab_only',  -- one entry per tabpage: number + active file, no window list
        option = {
          nerdfont = true,  -- use icon glyphs (your font already renders them)
        },
      })
    end,
  },
}
