local treesitter = require('nvim-treesitter.configs')

treesitter.setup {
  ensure_installed = {"lua", "python", "java"},
  highlight = {
      enable = true
  }
}
