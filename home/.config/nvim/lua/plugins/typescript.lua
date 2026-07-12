return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        vtsls = {
          settings = {
            typescript = {
              preferences = {
                includePackageJsonAutoImports = "on",
              },
            },
            javascript = {
              preferences = {
                includePackageJsonAutoImports = "on",
              },
            },
          },
        },
      },
    },
  },
}
