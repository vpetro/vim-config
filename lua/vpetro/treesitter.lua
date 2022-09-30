local treesitter = require('nvim-treesitter.configs')

treesitter.setup {
  ensure_installed = {"lua", "python", "java", "scala"},
  highlight = {
      enable = true
  }
}
