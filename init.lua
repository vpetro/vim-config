vim.pack.add({
  {
    src = 'https://github.com/vpetro/vim-petro-colors',
    name = 'petro-colors'
  },
  { src = 'https://github.com/catppuccin/nvim' },

  -- treesitter
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter', branch = 'main' },
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter-textobjects', branch = 'main' },

  -- generic lsp
  { src = 'https://github.com/nvim-lua/plenary.nvim' },
  { src = 'https://github.com/nvimtools/none-ls.nvim' },

  -- git
  { src = 'https://github.com/tpope/vim-fugitive' },

  -- better netrw
  { src = 'https://github.com/tpope/vim-vinegar' },

  -- comments
  { src = 'https://github.com/tpope/vim-commentary' },

  -- surrounding text objects
  { src = 'https://github.com/tpope/vim-surround' },

  -- distraction free mode
  { src = 'https://github.com/junegunn/goyo.vim' },

  -- fuzzy finder
  { src = 'https://github.com/ibhagwan/fzf-lua' },

  -- completion & snippets
  { src = 'https://github.com/saghen/blink.cmp', version = vim.version.range('1.*') },

  { src = "https://github.com/iamcco/markdown-preview.nvim" },

  { src = "https://github.com/sindrets/diffview.nvim" }

})

-- Default to the true-color theme; :Petro toggles back to the 256-color one.
vim.cmd.colorscheme("petro-tc")

vim.opt.swapfile = false
vim.opt.background = "dark"
vim.opt.termguicolors = true

vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.expandtab = true
vim.opt.smartindent = true

vim.opt.list = true
vim.opt.listchars = {
  tab = '» ',
  extends = '»',
  precedes = '«',
}

vim.opt.suffixes = {
  '.bak',
  '.swp',
  '.o',
  '.info',
  '.aux',
  '.log',
  '.dvi',
  '.bbl',
  '.blg',
  '.brf',
  '.cb',
  '.ind',
  '.idx',
  '.ilg',
  '.inx',
  '.out',
  '.toc',
  '.cmi',
  '.cmo',
  '.cmx',
  '.cmxa',
  '.exe',
  '.ho',
  '.hi',
  '.bc',
  '.annot',
  '.spot'
}

vim.opt.wildignore = {
  '*/.hg/*',
  '*/.svn/*',
  '*/images/*',
  '*/target/*',
  '*/.idea/*',
  '*.dll',
  '*.exe',
  '*.o',
  '*.obj',
  '*.class',
  '*.pyc',
  '*.pidb',
  '*.jar',
  '*.class',
  '*.aux',
  '*.bbl',
  '*.blg',
  '*.fdb_latexmk',
  '*.bst',
  '*.pdf',
  '*.png',
  '*.jpg',
  '*.gif',
  '*.bson',
  '*.snb'
}

vim.opt.number = false
vim.opt.relativenumber = false

vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.wrap = false

vim.opt.signcolumn = 'yes'

vim.opt.completeopt = { 'menu', 'menuone', 'noinsert' }
vim.opt.shortmess:append('c')


require('fzf-lua').setup({
  winopts = {
    split = 'botright 20new',
    border = 'single',
    preview = {
      hidden = 'hidden',
      border = 'border',
      title = false,
      layout = 'horizontal',
      horizontal = 'right:50%',
    },
  },
  fzf_opts = {
    ['--pointer'] = '>',
    ['--marker'] = '+',
  },
  -- Map the inner fzf process's colors onto nvim highlight groups so the
  -- fzf window matches whichever petro variant is active (petro or petro-tc).
  -- fzf-lua resolves cterm vs gui automatically based on termguicolors.
  fzf_colors = {
    ["fg"]      = { "fg", "Normal" },
    ["bg"]      = "-1",                       -- inherit terminal bg
    ["hl"]      = { "fg", "Type" },           -- query matches in unselected (gold)
    ["fg+"]     = { "fg", "Normal" },
    ["bg+"]     = { "bg", "Visual" },         -- selected line bg (bg_alt)
    ["hl+"]     = { "fg", "Function" },       -- query matches in selected (orange)
    ["info"]    = { "fg", "Comment" },        -- "10/100" counter
    ["prompt"]  = { "fg", "Function" },
    ["pointer"] = { "fg", "Function" },       -- the '>' pointer
    ["marker"]  = { "fg", "Type" },           -- the '+' multi-select marker
    ["spinner"] = { "fg", "Type" },
    ["header"]  = { "fg", "Comment" },
    ["gutter"]  = "-1",                       -- left margin (inherit terminal bg)
    ["border"]  = { "fg", "FloatBorder" },
  },
  keymap = {
    -- keybindings passed to the fzf binary (only work if fzf is installed)
    fzf = {
      ['ctrl-j'] = 'down',
      ['ctrl-k'] = 'up',
      ['ctrl-n'] = 'down',
      ['ctrl-p'] = 'up',
    },
    -- neovim-level keybindings for the fzf-lua window
    builtin = {
      ['<C-j>'] = 'down',
      ['<C-k>'] = 'up',
      ['<C-n>'] = 'down',
      ['<C-p>'] = 'up',
    },
  },
})

require('catppuccin').setup({
  background = { dark = 'macchiato' }
})

-- Markdown (and other @markup.*) highlights for the 256-color petro theme.
-- Treesitter highlights markdown via @markup.* groups, which petro.vim never
-- defines, so markdown fell back to Neovim's bland defaults (all headings the
-- same colorless Title group, inline code as Comment gray, etc).
-- Registered as a ColorScheme autocmd so the groups survive the FocusGained
-- colorscheme re-apply and the :Petro toggle. petro-tc defines its own.
local function petro_markup_highlights()
  local function hl(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  -- Pull code colors straight from the active theme so markdown elements
  -- reuse the exact palette regular code gets.
  local function theme(name)
    return vim.api.nvim_get_hl(0, { name = name, link = false })
  end
  local str, stmt, cmnt, const, kw =
    theme("String"), theme("Statement"), theme("Comment"), theme("Constant"), theme("Keyword")

  -- headings: mirror markdownH1-H3 from petro.vim, extended through H6
  hl("@markup.heading", { ctermfg = 179, cterm = { bold = true }, bold = true })
  hl("@markup.heading.1", { ctermfg = 13, cterm = { bold = true }, bold = true })
  hl("@markup.heading.2", { ctermfg = 12, cterm = { bold = true }, bold = true })
  hl("@markup.heading.3", { ctermfg = 74, cterm = { bold = true }, bold = true })
  hl("@markup.heading.4", { ctermfg = 108 })
  hl("@markup.heading.5", { ctermfg = 109 })
  hl("@markup.heading.6", { ctermfg = 179 })

  -- inline emphasis. Bold fonts are disabled in the terminal on purpose,
  -- so give **strong** text a warm peach fg (Function color family) to
  -- lift it off the gray body text (bold attr kept for terminals that
  -- honor it).
  hl("@markup.strong", { ctermfg = 180, cterm = { bold = true }, bold = true })
  hl("@markup.italic", { cterm = { italic = true }, italic = true })
  hl("@markup.underline", { cterm = { underline = true }, underline = true })
  hl("@markup.strikethrough", { cterm = { strikethrough = true }, strikethrough = true })

  -- links: Keyword blue labels, Constant cyan urls
  hl("@markup.link", { fg = kw.fg, ctermfg = kw.ctermfg })
  hl("@markup.link.label", { fg = kw.fg, ctermfg = kw.ctermfg })
  hl("@markup.link.url", { fg = const.fg, ctermfg = const.ctermfg, cterm = { underline = true }, underline = true })

  -- inline code: same color as code strings
  hl("@markup.raw", { fg = str.fg, ctermfg = str.ctermfg })
  -- fenced code blocks: no tint; the injected language highlighting colors
  -- the block exactly like a regular source buffer
  hl("@markup.raw.block", { link = "Normal" })

  -- list bullets: Statement brown; tasks use String/Comment colors
  hl("@markup.list", { fg = stmt.fg, ctermfg = stmt.ctermfg })
  hl("@markup.list.checked", { fg = str.fg, ctermfg = str.ctermfg })
  hl("@markup.list.unchecked", { fg = cmnt.fg, ctermfg = cmnt.ctermfg })

  -- blockquotes: Comment gray, italicized
  hl("@markup.quote", { fg = cmnt.fg, ctermfg = cmnt.ctermfg, cterm = { italic = true }, italic = true })

  -- legacy regex-syntax groups (used anywhere treesitter isn't running)
  hl("markdownH4", { link = "@markup.heading.4" })
  hl("markdownH5", { link = "@markup.heading.5" })
  hl("markdownH6", { link = "@markup.heading.6" })
  hl("markdownCode", { link = "@markup.raw" })
  hl("markdownCodeBlock", { link = "@markup.raw" })
  hl("markdownLinkText", { link = "@markup.link.label" })
  hl("markdownUrl", { link = "@markup.link.url" })
  hl("markdownListMarker", { link = "@markup.list" })
  hl("markdownBlockquote", { link = "@markup.quote" })
end

vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "petro",
  callback = petro_markup_highlights,
})

-- petro-tc defines the full @markup.* set itself; layer on the markdown
-- decisions made in this config (true-color twins of the petro tweaks).
local function petro_tc_markup_overrides()
  -- bold fonts are disabled in the terminal on purpose, so **strong**
  -- text gets a muted peach fg instead (hex twin of cterm 180)
  vim.api.nvim_set_hl(0, "@markup.strong", { fg = "#D7AF87", bold = true })
  -- fenced code blocks: no tint; the injected language highlighting
  -- colors them exactly like a regular source buffer
  vim.api.nvim_set_hl(0, "@markup.raw.block", { link = "Normal" })
  -- task list states (not defined by the theme)
  vim.api.nvim_set_hl(0, "@markup.list.checked", { fg = "#87AF00" })   -- String olive
  vim.api.nvim_set_hl(0, "@markup.list.unchecked", { fg = "#6C6C6C" }) -- Comment gray
end

vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "petro-tc",
  callback = petro_tc_markup_overrides,
})

-- Make fzf-lua windows match the (transparent) editor background.
-- petro-tc links FzfLua* to NormalFloat -- a solid #1C1C1C panel -- so the
-- picker rendered as a grey theme floating on the black editor body. Re-point
-- the fzf surfaces at Normal (which is bg=NONE -> the terminal background
-- shows through, same as the editor) and drop the panel bg off the
-- border/title so only their accent fg remains. The border/title fg is read
-- from the theme at runtime, so there's no palette to keep in sync.
-- (petro.vim leaves fzf-lua at its defaults, which already link to Normal, so
-- this override is only registered for petro-tc.)
local function petro_tc_fzf_overrides()
  local function fg_on_transparent(src, extra)
    local h = vim.api.nvim_get_hl(0, { name = src, link = false })
    local res = { fg = h.fg, ctermfg = h.ctermfg, bg = "NONE", ctermbg = "NONE" }
    for k, v in pairs(extra or {}) do res[k] = v end
    return res
  end
  vim.api.nvim_set_hl(0, "FzfLuaNormal", { link = "Normal" })
  vim.api.nvim_set_hl(0, "FzfLuaPreviewNormal", { link = "Normal" })
  vim.api.nvim_set_hl(0, "FzfLuaBorder", fg_on_transparent("FloatBorder"))
  vim.api.nvim_set_hl(0, "FzfLuaPreviewBorder", fg_on_transparent("FloatBorder"))
  vim.api.nvim_set_hl(0, "FzfLuaTitle", fg_on_transparent("FloatTitle", { bold = true }))
  vim.api.nvim_set_hl(0, "FzfLuaPreviewTitle", fg_on_transparent("FloatTitle", { bold = true }))
end

vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "petro-tc",
  callback = petro_tc_fzf_overrides,
})


-- Toggle commands to compare the original 256-color theme against the
-- true-color rewrite without ripping out either one.
vim.api.nvim_create_user_command("Petro", function()
  vim.opt.termguicolors = false
  vim.cmd.colorscheme("petro")
end, { desc = "Use the original 256-color petro theme" })

vim.api.nvim_create_user_command("PetroTC", function()
  vim.opt.termguicolors = true
  vim.cmd.colorscheme("petro-tc")
end, { desc = "Use the true-color petro-tc theme" })

-- Dim neovim when tmux pane loses focus.
-- The FocusGained callback re-applies whatever colorscheme is currently
-- active so toggling via :PetroTC / :Petro survives a focus change.
vim.api.nvim_create_autocmd("FocusLost", {
  callback = function()
    vim.api.nvim_set_hl(0, "Normal", { bg = "#1e2028" })
    vim.api.nvim_set_hl(0, "NormalNC", { bg = "#1e2028" })
  end,
})
vim.api.nvim_create_autocmd("FocusGained", {
  callback = function()
    if vim.g.colors_name and vim.g.colors_name ~= "" then
      vim.cmd.colorscheme(vim.g.colors_name)
    end
  end,
})

vim.g.mapleader = ' '

vim.keymap.set('n', '<leader>q', ':q!<cr>')
vim.keymap.set('n', '<leader>w', ':w!<cr>')

vim.keymap.set('n', '<C-n>', ':nohl<CR>')
vim.keymap.set('n', 'n', 'nzz')
vim.keymap.set('n', 'N', 'Nzz')
vim.keymap.set('n', '*', '*zz')
vim.keymap.set('n', '#', '#zz')
vim.keymap.set('n', 'g*', 'g*zz')
vim.keymap.set('n', 'g#', 'g#zz')

vim.keymap.set('n', '<C-h>', '<C-w>h')
vim.keymap.set('n', '<C-j>', '<C-w>j')
vim.keymap.set('n', '<C-k>', '<C-w>k')
vim.keymap.set('n', '<C-l>', '<C-w>l')

vim.keymap.set('n', '<leader>t', '<cmd>FzfLua git_files<cr>')
vim.keymap.set('n', '<leader>f', '<cmd>FzfLua files<cr>')

local function maximize_split()
  vim.cmd('mksession! ~/.session.vim')
  vim.cmd.only()
end

vim.keymap.set('n', '<C-w>u', ':source ~/.session.vim<cr>')
vim.keymap.set('n', '<C-w>o', maximize_split)

vim.keymap.set('n', '<leader>gm', ':Gvdiffsplit main<CR>')
vim.keymap.set('n', '<leader>gh', ':Gclog -- %<CR>')


-- LSP

vim.diagnostic.config({
  virtual_text = false,
  -- Print the full diagnostic message under the line the cursor is on.
  -- TypeScript errors are wordy but instructive, so seeing them inline (no
  -- hover needed) is a good way to learn. Set to false if it feels jumpy.
  virtual_lines = { current_line = true },
  signs = true,
  update_in_insert = false,
  underline = true,
})

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local opts = { buffer = args.buf }

    vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)

    vim.keymap.set('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
    vim.keymap.set('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
    vim.keymap.set('n', 'gu', '<cmd>lua vim.lsp.buf.references()<CR>', opts)

    vim.keymap.set('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
    vim.keymap.set('n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)

    vim.keymap.set('n', '<leader>bb',
      function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
      end,
      opts
    )

    vim.keymap.set('n', '[d', function() vim.diagnostic.jump({ count = -1, float = true }) end, opts)
    vim.keymap.set('n', ']d', function() vim.diagnostic.jump({ count = 1, float = true }) end, opts)
    vim.keymap.set('n', 'gl', '<cmd>lua vim.diagnostic.setloclist()<CR>', opts)
    vim.keymap.set('n', '<space>e', '<cmd>lua vim.diagnostic.open_float({scope = "line"})<CR>', opts)
    vim.keymap.set('n', 'gw', '<cmd>lua vim.lsp.buf.format()<CR>', opts)

    vim.keymap.set("n", "gd",
      function()
        vim.cmd("vertical botright split")
        vim.lsp.buf.definition()
        vim.cmd("normal! zz")
      end,
      opts
    )

    -- While learning TS: auto-show inlay hints in TS/JS buffers. Other servers
    -- (gopls etc.) have their hint categories disabled, so this is effectively
    -- TS/JS-only. <leader>bb still toggles hints on/off.
    local ft = vim.bo[args.buf].filetype
    if ft:match('^typescript') or ft:match('^javascript') then
      vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
    end
  end
})



vim.lsp.enable('lua_ls')
vim.lsp.enable('python')
vim.lsp.enable("ty")
vim.lsp.enable('go')
vim.lsp.enable('typespec')
vim.lsp.enable('tsgo')

local null_ls = require('null-ls')
local formatting = null_ls.builtins.formatting

null_ls.setup({
  sources = {
    formatting.stylua.with {
      extra_args = { "--indent-type Spaces", "--indent-width 2" }
    },
    formatting.isort,
  },
})

require("blink.cmp").setup({
  signature = { enabled = true },
  completion = {
    list = {
      selection = { preselect = false, auto_insert = true } },
    menu = {
      auto_show = false,
    },
  },
  keymap = {
    ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
    ['<C-e>'] = { 'hide', 'fallback' },
    ['<CR>'] = { 'accept', 'fallback' },

    ['<Tab>'] = { 'snippet_forward', 'fallback' },
    ['<S-Tab>'] = { 'snippet_backward', 'fallback' },

    ['<Up>'] = { 'select_prev', 'fallback' },
    ['<Down>'] = { 'select_next', 'fallback' },
    ['<C-p>'] = { 'select_prev', 'fallback' },
    ['<C-n>'] = { 'select_next', 'fallback' },

    ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
    ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },

    ['<C-k>'] = { 'show_signature', 'hide_signature', 'fallback' },
  }
})

-- Register custom typespec parser for nvim-treesitter main branch
vim.api.nvim_create_autocmd('User', { pattern = 'TSUpdate',
callback = function()
  require('nvim-treesitter.parsers').typespec = {
    install_info = {
      url = 'https://github.com/happenslol/tree-sitter-typespec',
      branch = 'main',
    },
  }
end})

vim.filetype.add({
  extension = {
    tsp = "typespec",
  },
})

-- Install parsers (no-op if already installed)
require('nvim-treesitter').install {
  "markdown", "markdown_inline",
  "bash",
  "query",
  "lua", "vimdoc",
  "python",
  "json", "yaml",
  "javascript", "typescript",
  "go",
}

-- Enable treesitter highlighting and indentation for all filetypes
vim.api.nvim_create_autocmd('FileType', {
  callback = function()
    pcall(vim.treesitter.start)
    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})

-- Textobjects (main branch API)
require('nvim-treesitter-textobjects').setup {
  select = {
    lookahead = true,
  },
}

vim.keymap.set({ 'x', 'o' }, 'af', function()
  require('nvim-treesitter-textobjects.select').select_textobject('@function.outer', 'textobjects')
end)
vim.keymap.set({ 'x', 'o' }, 'if', function()
  require('nvim-treesitter-textobjects.select').select_textobject('@function.inner', 'textobjects')
end)
vim.keymap.set({ 'x', 'o' }, 'ac', function()
  require('nvim-treesitter-textobjects.select').select_textobject('@class.outer', 'textobjects')
end)
vim.keymap.set({ 'x', 'o' }, 'ic', function()
  require('nvim-treesitter-textobjects.select').select_textobject('@class.inner', 'textobjects')
end)

vim.opt.runtimepath:prepend(vim.env.HOME .. "/code/petro/mentat")

require("mentat").setup({
  provider = "anthropic",
  slots = {
    quick = { model = "claude-opus-5", thinking = "medium" },
    big = { model = "claude-fable-5", thinking = "max" },
  },
})

vim.g.mkdp_auto_close = 0
vim.g.mkdp_theme = "dark"

vim.keymap.set("n", "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>", { desc = "Markdown preview" })

-- Toggle a markdown checkbox on the given line, cycling on repeat press:
--   "buy milk"     -> "- [ ] buy milk"   (plain text -> checkbox item)
--   "- buy milk"   -> "- [ ] buy milk"   (list item  -> checkbox item)
--   "- [ ] milk"   -> "- [x] milk"       (uncheck    -> checked)
--   "- [x] milk"   -> "- [ ] milk"       (checked    -> unchecked)
local function md_toggle_checkbox(lnum)
  local line = vim.fn.getline(lnum)
  if line:match("^%s*[-*+]%s+%[[xX]%]") then
    line = line:gsub("(%[)[xX](%])", "%1 %2", 1)      -- checked -> unchecked
  elseif line:match("^%s*[-*+]%s+%[ %]") then
    line = line:gsub("(%[) (%])", "%1x%2", 1)         -- unchecked -> checked
  else
    local indent, marker, rest = line:match("^(%s*)([-*+]%s+)(.*)$")
    if marker then
      line = indent .. marker .. "[ ] " .. rest       -- list item -> checkbox
    else
      local ind, content = line:match("^(%s*)(.*)$")
      line = ind .. "- [ ] " .. content               -- plain line -> checkbox item
    end
  end
  vim.fn.setline(lnum, line)
end

-- Open a new line below and drop in an HTML comment tagged "PV:" for
-- annotating docs. The comment is invisible in rendered markdown but trivial
-- to grep ("PV:"). Lands you in insert mode right after the tag:
--   <!-- PV: | -->
local function md_insert_pv_comment(lnum)
  local indent = vim.fn.getline(lnum):match("^(%s*)") or ""
  local prefix = indent .. "<!-- PV: "
  vim.fn.append(lnum, prefix .. " -->")
  vim.api.nvim_win_set_cursor(0, { lnum + 1, #prefix })
  vim.cmd("startinsert")
end

-- Nicer reading/editing defaults for markdown buffers.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.wrap = true        -- prose: soft-wrap long lines
    vim.opt_local.linebreak = true   -- ...breaking at word boundaries
    vim.opt_local.breakindent = true -- wrapped lines keep list indentation

    vim.keymap.set("n", "<leader>x", function()
      md_toggle_checkbox(vim.fn.line("."))
    end, { buffer = true, desc = "Toggle markdown checkbox" })

    vim.keymap.set("x", "<leader>x", function()
      local a, b = vim.fn.line("v"), vim.fn.line(".")
      if a > b then a, b = b, a end
      for l = a, b do md_toggle_checkbox(l) end
      vim.api.nvim_input("<Esc>")
    end, { buffer = true, desc = "Toggle markdown checkbox" })

    vim.keymap.set("n", "<leader>c", function()
      md_insert_pv_comment(vim.fn.line("."))
    end, { buffer = true, desc = "Insert PV: HTML comment" })
  end,
})

require("diffview").setup({
  merge_tool = {
    layout = "diff3_mixed",  -- or "diff3_horizontal", "diff3_plain"
  },
})
