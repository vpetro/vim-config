local ls = require'luasnip'
local s = ls.snippet
local t = ls.text_node

ls.snippets = {
  all = {
    s("tgg", t("Wow! Text!")),
  }
}
