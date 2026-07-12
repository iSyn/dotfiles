-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- paste over selection without clobbering the clipboard
vim.keymap.set("x", "p", [["_dP]], { desc = "Paste without yank" })

-- half page scroll and recenter
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Scroll down + center" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Scroll up + center" })

-- copy project-relative file path (prefixed with @) to system clipboard
vim.keymap.set("n", "<leader>cp", function()
  local path = vim.fn.expand("%:p")
  local rel = vim.fs.relpath(LazyVim.root(), path) or path
  local mention = "@" .. rel
  vim.fn.setreg("+", mention)
  vim.notify("Copied: " .. mention)
end, { desc = "Copy relative file path (@)" })
