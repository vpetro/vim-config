return {
  cmd = { 'tsc', '--lsp', '--stdio' },
  filetypes = {
    'javascript',
    'javascriptreact',
    'javascript.jsx',
    'typescript',
    'typescriptreact',
    'typescript.tsx',
  },
  root_markers = { 'tsconfig.json', 'jsconfig.json', 'package.json', '.git' },
  -- Inlay hints turned ON to help learn TypeScript: the editor prints the
  -- types it INFERS -- variable types, function return types, parameter names
  -- at call sites -- right in the buffer, so you see what the type system is
  -- doing. <leader>bb (see init.lua) toggles them off when they get noisy.
  -- The suppressWhen* flags hide hints that would just restate an obvious
  -- name. Dial parameterNames to 'literals' or 'none' if call sites feel busy.
  settings = {
    typescript = {
      inlayHints = {
        parameterNames = { enabled = 'all', suppressWhenArgumentMatchesName = true },
        parameterTypes = { enabled = true },
        variableTypes = { enabled = true, suppressWhenTypeMatchesName = true },
        propertyDeclarationTypes = { enabled = true },
        functionLikeReturnTypes = { enabled = true },
        enumMemberValues = { enabled = true },
      },
    },
    javascript = {
      inlayHints = {
        parameterNames = { enabled = 'all', suppressWhenArgumentMatchesName = true },
        parameterTypes = { enabled = true },
        variableTypes = { enabled = true, suppressWhenTypeMatchesName = true },
        propertyDeclarationTypes = { enabled = true },
        functionLikeReturnTypes = { enabled = true },
        enumMemberValues = { enabled = true },
      },
    },
  },
}
