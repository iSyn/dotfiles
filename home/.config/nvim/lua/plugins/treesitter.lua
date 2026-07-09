return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'master',
    lazy = false,  -- load at startup so highlighting is ready immediately
    build = ':TSUpdate',  -- compile/update parsers after install
    main = 'nvim-treesitter.configs',  -- run setup() on this module
    opts = {
      ensure_installed = { 'tsx', 'javascript', 'typescript', 'lua', 'vim', 'vimdoc', 'bash', 'json', 'yaml', 'markdown', 'markdown_inline' },
      auto_install = true,  -- install missing parsers when opening a new filetype
      highlight = { enable = true },
      indent = { enable = true },
    },
  },
}
