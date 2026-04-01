--- init.lua

--- Set leader and install plugins
vim.g.mapleader = " "
vim.keymap.set('n', '<Space>', '<Nop>') --- disable Space from moving cursor since it's our leader key
vim.pack.add({
	{ src = "https://github.com/rebelot/kanagawa.nvim" },
	{ src = "https://github.com/neovim/nvim-lspconfig" },
	{ src = "https://github.com/echasnovski/mini.pick" },
	{ src = "https://github.com/stevearc/oil.nvim" },
	{ src = "https://codeberg.org/ziglang/zig.vim" },
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter" },
})

-- Set the colorscheme
vim.cmd.colorscheme "kanagawa-dragon"
vim.cmd(":hi statusline guibg=NONE")
vim.o.winborder = "rounded"
-- vim.g.have_nerd_font = true

vim.opt.cmdheight = 0 -- set the command line to be hidden

--negative value means to use value of shiftwidth
vim.opt.tabstop = 4
vim.opt.softtabstop = -1
vim.opt.shiftwidth = 4 -- how much to indent when using >> <<
vim.opt.breakindent = true
vim.opt.smartindent = true
vim.opt.autoindent = true
vim.opt.list = true -- enable showing blank space chars as you type
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Set visibility of line numbers and relative numbers
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = 'yes' -- always reserve space for the signs
vim.opt.scrolloff = 4
vim.opt.colorcolumn = "120"

vim.opt.mouse = 'a'
vim.opt.showmode = false

-- use an undo file to record undo history
vim.opt.undofile = true
vim.opt.swapfile = false
vim.opt.backup = false

-- use case insensitive search by default
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true

vim.opt.updatetime = 300
vim.opt.timeoutlen = 400

-- split new windows to the right and down
vim.opt.splitright = true
vim.opt.splitbelow = true

-- make it so that pressing enter after a comment doesn't continue the comment
-- vim.opt.formatoptions:remove('c')
-- vim.opt.formatoptions:remove('r')
vim.opt.formatoptions:remove('o')

vim.opt.inccommand = 'split'
vim.opt.confirm = true -- raise a dialog instead of failing commands
vim.opt.laststatus = 3

-- we don't have tee, so remove it from the shell pipe
vim.opt.shellpipe = ">%s 2>&1"

--- Setup Keybinds
vim.keymap.set('n', '<leader>o', ':update<CR>:source<CR>')
vim.keymap.set('n', '<leader>w', ':write<CR>')
vim.keymap.set('n', '<leader>q', ':quit<CR>')
vim.keymap.set('n', '<leader>i', '<CMD>e $MYVIMRC<CR>')
vim.keymap.set({ 'n', 'v', 'x' }, '<leader>y', '"+y<CR>') -- yank to system clipboard
vim.keymap.set({ 'n', 'v', 'x' }, '<leader>d', '"+d<CR>') -- delete to system clipboard

vim.keymap.set('n', '<leader>m', function()
	vim.fn.setqflist({}, 'r')
	vim.cmd("make")

	local qflist = vim.fn.getqflist()
	if #qflist > 0 then
		vim.cmd("copen")
	else
		print("Make: no errors")
	end
end
, { desc = "Run :make and open quickfixlist" })


-- clear highlight on <CR>
vim.keymap.set('n', '<CR>', function()
	if vim.v.hlsearch == 1 then
		vim.cmd("nohlsearch")
		return ''
	else
		return '<CR>'
	end
end, { desc = "Clear search highlight on Enter" })

-- Setup HLSL filetype extensions
vim.filetype.add({
  extension = {
    hlsl = "hlsl",
  },
  pattern = {
    [".*%.vert%.hlsl"] = "hlsl",
    [".*%.frag%.hlsl"] = "hlsl",
    [".*%.comp%.hlsl"] = "hlsl",
  },
})

local ts_group = vim.api.nvim_create_augroup("TreesitterStarter", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
    group = ts_group,
    pattern = { "hlsl", "zig", "c", "cpp", "lua" },
    callback = function(args)
        local _, _ = pcall(vim.treesitter.start, args.buf)
    end,
})

-- Setup Treesitter
require'nvim-treesitter'.setup { install_dir = vim.fn.stdpath('data') .. '/site' }
require'nvim-treesitter'.install { 'lua', 'vim', 'vimdoc', 'c', 'cpp', 'zig', 'hlsl' }
vim.treesitter.language.register('hlsl', { 'hlsl' })


-- Terminal setup
local term_bufnr = nil
local term = "bash"

local function toggle_terminal()
	-- this func will try to toggle a persistent terminal buffer
	if term_bufnr and vim.api.nvim_buf_is_valid(term_bufnr) then
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			if vim.api.nvim_win_get_buf(win) == term_bufnr then
				vim.api.nvim_win_hide(win)
				return
			end
		end

		-- Not visible, toggle open
		vim.cmd('botright split')
		vim.api.nvim_win_set_buf(0, term_bufnr)
		vim.cmd('resize 12')
		return
	end

	local command = "botright split term://" .. term
	vim.cmd(command)
	vim.cmd('resize 12')
	term_bufnr = vim.api.nvim_get_current_buf()
end

-- enter insert mode when opening a term
vim.api.nvim_create_autocmd("TermOpen", {
	pattern = "*",
	callback = function()
		vim.cmd("startinsert")
	end,
})

vim.keymap.set('n', '<leader>t', toggle_terminal, { desc = 'Open a terminal' })
vim.keymap.set('t', '<Esc>', [[<C-\><C-n>]], { desc = 'Exit terminal mode with Esc' })

--- Configure LSPs to enable
vim.diagnostic.config({
	virtual_text = true,
	signs = true,
	update_in_insert = true,
})

vim.lsp.enable({ "lua_ls" })
vim.lsp.config("lua_ls", {
	settings = {
		Lua = {
			workspace = {
				library = vim.api.nvim_get_runtime_file("", true),
			}
		}
	}
})
vim.keymap.set('n', '<leader>cf', vim.lsp.buf.format)

-- Setup for zig lsp
vim.g.zig_fmt_parse_errors = 0
vim.g.zig_fmt_autosave = 0

vim.lsp.config("zls", {
	cmd = { 'zls' },
	filetypes = { 'zig' },
	root_markers = { 'build.zig' },
})
vim.lsp.enable({ "zls" })

vim.api.nvim_create_autocmd('BufWritePre', {
	pattern = { "*.zig", "*.zon" },
	callback = function(ev)
		vim.lsp.buf.format()
	end
})


-- Function for toggling the quickfix list on/off
local function toggle_qf()
	local is_open = false
	for _, win in ipairs(vim.fn.getwininfo()) do
		if win.quickfix == 1 then
			is_open = true
			break
		end
	end

	if is_open then
		vim.cmd("cclose")
	else
		vim.cmd("copen")
	end
end

-- local function toggle_loclist()
-- 	local is_open = false
-- 	for _, win in ipairs(vim.fn.getwininfo()) do
-- 		if win.quickfix == 1 then
-- 			is_open = true
-- 			break
-- 		end
-- 	end
--
-- 	if is_open then
-- 		vim.cmd("lclose")
-- 	else
-- 		vim.cmd("lopen")
-- 	end
-- end

vim.keymap.set('n', '<leader>cd', vim.diagnostic.open_float, { desc = "Show line diagnostics" })
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = "Go to prev diagnostics" })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = "Go to next diagnostics" })
-- vim.keymap.set('n', '<leader>cq', toggle_loclist, { desc = "Open local list" })
vim.keymap.set('n', '<leader>k', toggle_qf, { desc = "Open quickfix list" })
vim.keymap.set('n', '<leader>cf', function() vim.lsp.buf.format({ async = true }) end,
	{ desc = "Format current buffer with LSP" })
vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { desc = "Run LSP Code Actions on current buffer" })
vim.keymap.set('n', '<leader>cr', vim.lsp.buf.rename, { desc = "Rename symbol under cursor" })
vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { desc = "Go to definition" })
vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, { desc = "Go to declaration" })
vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, { desc = "Go to implementation" })
vim.keymap.set('n', 'gt', vim.lsp.buf.type_definition, { desc = "Go to type definition" })
vim.keymap.set('n', 'gr', vim.lsp.buf.references, { desc = "Go to references" })
vim.keymap.set('n', 'K', vim.lsp.buf.hover, { desc = "Show documentation" })
vim.keymap.set('i', '<C-k>', vim.lsp.buf.signature_help, { desc = "Show documentation" })
vim.keymap.set('n', '<leader>lr', function()
	vim.lsp.stop_client(vim.lsp.get_clients({ bufnr = 0 }))
	vim.cmd.edit()
end, { desc = "Restart LSP" })

vim.keymap.set('n', '<leader>li', function()
	print(vim.inspect(vim.lsp.get_clients({ bufnr = 0 })))
end, { desc = "List LSP Clients" })


vim.api.nvim_create_autocmd('LspAttach', {
	callback = function(ev)
		local client = vim.lsp.get_client_by_id(ev.data.client_id)
		if client:supports_method('textDocument/completion') then
			vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
		end
	end,
})
-- menu show a completion menu
-- menuone show even if only one result
-- noinsert don't insert the first match automatically
-- noselect Don't have omnicomplete autoselect the first thing
-- preview show documentation in preview window
vim.cmd("set completeopt+=menu,menuone,noinsert,preview")
vim.opt.pumheight = 10

--- Setup Pick(er)
require "mini.pick".setup()
vim.keymap.set('n', '<leader>sf', ":Pick files<CR>")
vim.keymap.set('n', '<leader>sh', ":Pick help<CR>")
vim.keymap.set('n', '<leader>sg', ":Pick grep_live<CR>")
vim.keymap.set('n', '<leader>sb', ":Pick buffers<CR>")

--- Setup Oil (file browser/editor)
require "oil".setup({
	view_options = {
		show_hidden = true,
	},
	columns = {
		"icon",
		"size",
	},
})
vim.keymap.set('n', '<leader>e', function() require('oil').toggle_float() end, { desc = "Toggle Oil floating window" })
--- Existing default Oil keymaps when using Oil
-- ["<C-s>"] = { "actions.select", opts = { vertical = true } },
-- ["<C-h>"] = { "actions.select", opts = { horizontal = true } },
-- ["<C-t>"] = { "actions.select", opts = { tab = true } },
-- ["<C-p>"] = "actions.preview",
-- ["<C-c>"] = { "actions.close", mode = "n" },
-- ["<C-l>"] = "actions.refresh",
-- ["-"] = { "actions.parent", mode = "n" },
-- ["_"] = { "actions.open_cwd", mode = "n" },
-- ["gs"] = { "actions.change_sort", mode = "n" },
-- ["gx"] = "actions.open_external",
-- ["g."] = { "actions.toggle_hidden", mode = "n" },
-- ["g\\"] = { "actions.toggle_trash", mode = "n" },


--- Notes on things to remember
---
--- Movement:
---   f/t work with ; and , to repeat
---   w and W, e and E, b and B, ge and gE for moving words
---   () for sentences
---   {} for paragraphs
---   [[ ]] ][ [] for braces/sections
---
---   m<letter> creates a mark (view with :marks)
---   '<letter> jumps to that mark
---   '' last jump, '. last change
---   '[ '] to begin/end of prev yanked text
---
---   % find the match of thing under cursor
---
--- Selectors:
---   aw iw aW iW selects a word or inner word
---   as is selects sentences
---   ap ip selects paragraphs
---   ab selects blocks of ()
---   aB selects blocks of {}
---   a'/" i'/" selects blocks of ' or "
---
--- Jumps:
---   '' goes to prev jump
---   CTRL-o CTLR-i go to prev/next jump location
---   :jumps lists the jumpgs
---   :cle[arjumps] clears the jumplist
---
---   {count}% jumps to a percentage through the file
---
---   [( [{ jumps to the previous unmatched ( or {
---   ]) ]} jumpts to next unmatched ) or }
---
---   ]m ]M go to the next start/end of a method
---   [m [M go to the previous start/end of a method
---
---   H to the Home (first line of window)
---   M to the Middle (middle line)
---   L to the bottom (lower line)
---
--- Changes:
---   :changes will show the changelist
---   g; goes to older changes
---   g, goes to later changes
---
--- Scrolling:
---   CTRL-e scroll window count lines down in the buffer
---   CTRL-d scroll the window down, default half-screen, see scroll option
---   CTRL-f scroll forwards count pages in the buffer
---
---   CTRL-Y scroll count lines upward in buffer
---   CTRL-U scroll window upwards (default half-screen see scroll option)
---   CTRL-B scroll Backwards a count pages in the buffer
---
---   z<CR> redraw with line at top of window put cursor on first non-blank in the line
---   zt    same as above but keep cursor at same column
---   z. zz  redraw, place line in center of window, first non-blank or keeps column
---   z- zb  redraw, place line at bottom of window, first non-blank or keeps column
---
--- Inserting:
---   CTRL-W delete the work before the cursor
---   CTRL-U delete all of the entered characters before the curosr in the current line
---
---   CTRL-N find next keyword
---   CTRL-P find previous keyword
---
---   CTRL-R Insert the contents of a register
---   CTRL-R CTRL-R inserts the literal text in register, not as if typed
---
---   Registers:
---     " unamed register, holds last yanked or delted text
---     % current filename
---     # alt filenamej
---     * clipboard contents
---     + clipboard contents
---     / last search pattern
---     : last command line
---     . last inserted text
---     - last small (less than line) delete
---
---   CTRL-T insert a 'tab' for the current line
---   CTRL-D remove a 'tab' for the current line
---
---   Special Sequences in Insert mode
---
---   CTRL-g and then vim motions can be used to move cursor without exiting insert mode
---   CTRL-O enter one command, then return to insert mode
---
--- Completions:
---   CTRL-X starts Xmode while inserting
---   CTRL-N will open up the completions
---   CTLR-P CTRL-N will scroll the popup for the completions
---   CTRL-E will cancel the completion
---   CTRL-Y will accept the completions
---
--- Changing Text
---
---   "<reg> all of the delete operators can specify a register first
---          then the text is deleted into that register to use for later
---
---   "<reg>p/P will put the text from <reg> at the cursor
---
---   ~ changes the Case of the text (use g~{motion})
---   U changes the text to upper case (use gU{motion})
---   u changes the text to lower case
---
---   CTRL-A increases the value of a number
---   CTRL-X decrease the value of a number
---
--- Visual Mode
---   v, V, or CTRL-Q (CTRL-V does things on Windows)
---   o/O will flip the end of the visual mode (O used in block mode)
---
--- Various
---   CTRL-L clears and redraws the screen
---   ga (get ascii) prints the ascii value of the character
---   g8 (get hex) prints the hex value
---   gx opens the current filepath or url at the cursor
---
--- Terminal
---   :terminal to start a shell
---   CTRL-\ CTRL-N to exit terminal mode
---   :!{cmd} execute cmd in the shell


-- """" Old vimrc from 2016
-- " Vimrc for connorw
--
-- " Setup Vundle
-- "set nocompatible
-- "filetype off
-- "
-- "set rtp+=~/.config/nvim/bundle/Vundle.vim
-- "call vundle#begin()
-- "
-- "Plugin 'VundleVim/Vundle.vim'
-- ""Plugin 'lervag/vimtex'
-- "Plugin 'scrooloose/nerdtree'
-- "Plugin 'tpope/vim-surround'
-- "Plugin 'tpope/vim-fugitive'
-- "
-- "call vundle#end()
-- "filetype plugin indent on
-- "" To install use :PluginInstall
-- "
-- "" Colors
-- "set background=dark
-- "colorscheme slate
-- "syntax enable
-- "set list      " Show tabs and newlines
-- "set listchars=tab:▸\ ,eol:¬
-- "
-- "" Spaces and Tabs
-- "set tabstop=2
-- "set shiftwidth=2
-- "set expandtab
-- "set smarttab
-- "set nocindent
-- "
-- "" Config
-- "set encoding=utf-8
-- "set fileencoding=utf-8
-- "set t_Co=256
-- "
-- "" Undo/Redo
-- "map <C-Z> :undo<return>
-- "map <C-S-Z> :redo<return>
-- "
-- "" Indentation
-- "set autoindent
-- "
-- "" UI Config
-- "set number
-- "set showcmd
-- "set cursorline
-- "filetype indent on
-- "set wildmenu
-- "set lazyredraw
-- "set showmatch
-- "
-- "" Color Column
-- "set colorcolumn=80
-- "
-- "" Backspaces
-- "set backspace=indent,eol,start
-- "
-- "" Search
-- "set incsearch
-- "set hlsearch
-- "set ignorecase
-- "set smartcase
-- "nnoremap <leader><space> :nohlsearch<CR>
-- "
-- "" Folding
-- "set foldenable
-- "set foldmethod=manual
-- "
-- "nnoremap j gj
-- "nnoremap k gk
-- "
-- "" Leader Shortcuts
-- "let mapleader=","
-- "inoremap jk <esc>
-- "
-- "set backup
-- "set backupdir=/var/tmp,/tmp
-- "set backupskip=/tmp/*
-- "set directory=/var/tmp,/tmp
-- "set writebackup
