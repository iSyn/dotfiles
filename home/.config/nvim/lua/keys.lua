-- save by pressing Esc
-- vim.keymap.set('n', '<Esc>', ':w<CR>', { desc = 'Save' })

-- select all by pressing ctrl + a
vim.keymap.set('n', '<C-a>', 'ggVG', { desc = 'Select All' })

-- pasting over a selection no longer clobbers your clipboard
vim.cmd([[ xnoremap <expr> p 'pgv"'.v:register.'y' ]])

-- moving half page + center
vim.keymap.set('n', '<C-d>', '<C-d>zz')
vim.keymap.set('n', '<C-u>', '<C-u>zz')
