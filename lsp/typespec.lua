return {
  name = "typespec",
  cmd = { "npx", "tsp-server", "--stdio" },
  filetypes = {"typespec", "tsp"},
  -- root_dir = vim.fs.dirname(vim.fs.find( { "tspconfig.yaml", "package.json" }, { upward = true })[1])
  root_dir = vim.fs.root(0, { ".git/", "pyproject.toml" }),
}
