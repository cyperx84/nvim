-- Enable the Lua module bytecode cache (Neovim 0.9+) before anything is required.
-- Biggest single startup win: avoids re-parsing/compiling every Lua module.
vim.loader.enable()

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.have_nerd_font = true
require 'options'
require 'keymaps'
require 'autocmds'
require 'lazy-bootstrap'
require 'lazy-plugins'
-- vim: ts=2 sts=2 sw=2 et
