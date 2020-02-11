set nocompatible
filetype off

call plug#begin('~/.vim/plugged')
Plug 'neoclide/coc.nvim', {'branch': 'release'} "Intellisense code completion
Plug 'crusoexia/vim-monokai' "Theme for vim"
Plug 'ctrlpvim/ctrlp.vim' "Fuzzy file/buffer finde
Plug 'itchyny/lightline.vim' "Prettier status bar
Plug 'tomtom/tcomment_vim' "syntax aware plugin for commenting. Use with <gc>|<gcc>
Plug 'easymotion/vim-easymotion'
Plug 'preservim/nerdtree'
call plug#end()

filetype plugin indent on

" Set theme
colorscheme monokai

" Ignore specific files when searching
set wildignore+=node_modules\\
let g:ctrlp_custom_ignore = 'node_modules\|DS_Store\'

" Turn on syntax highlighting.
syntax on

" Disable the default Vim startup message.
set shortmess+=I

" Show line numbers relative.
set number
set relativenumber

set tabstop=4
set shiftwidth=4
set expandtab

" Always show the status line at the bottom, even if you only have one window open.
set laststatus=2

" The backspace key has slightly unintuitive behavior by default. For example,
" by default, you can't backspace before the insertion point set with 'i'.
" This configuration makes backspace behave more reasonably, in that you can
" backspace over anything.
set backspace=indent,eol,start

" By default, Vim doesn't let you hide a buffer (i.e. have a buffer that isn't
" shown in any window) that has unsaved changes. This is to prevent you from "
" forgetting about unsaved changes and then quitting e.g. via `:qa!`. We find
" hidden buffers helpful enough to disable this protection. See `:help hidden`
" for more information on this.
set hidden

" This setting makes search case-insensitive when all characters in the string
" But becomes case-sensitive when there are capital letters"
set ignorecase
set smartcase

" Enable searching as you type, rather than waiting till you press enter.
set incsearch

" Unbind some useless/annoying default key bindings.
nmap Q <Nop> " 'Q' in normal mode enters Ex mode. You almost never want this.

" Disable audible bell because it's annoying.
set noerrorbells visualbell t_vb=

" Enable mouse support.
set mouse+=a

" Remapping some shortcuts
nnoremap U <C-R> " Remap redo to U"
command! Ff CtrlP " Remap CtrlP to Ff"
