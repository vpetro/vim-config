-- TypeScript / JavaScript LSP via tsgo (the native Go port, aka
-- TypeScript 7 / @typescript/native-preview). Install with:
--   npm install -g @typescript/native-preview   (provides the `tsgo` binary)
--
-- tsgo is a preview build: hover, go-to-definition, references, diagnostics,
-- completion and signature help all work; some refactors/code-actions are
-- not yet at full parity with tsserver. To fall back to the stable, fully
-- featured server, install vtsls (`npm i -g @vtsls/language-server`), swap the
-- `cmd` below for `{ 'vtsls', '--stdio' }`, and rename this file to vtsls.lua
-- (and `vim.lsp.enable('vtsls')` in init.lua).
return {
  cmd = { 'tsgo', '--lsp', '--stdio' },
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
