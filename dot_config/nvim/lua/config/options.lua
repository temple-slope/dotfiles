-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Copy via OSC52 (tmux/SSH 透過)、paste はローカル pbpaste。
-- OSC52 paste は regtype を失うため yy → p で行貼り付けが壊れる。
vim.g.clipboard = {
  name = "OSC 52 + pbpaste",
  copy = {
    ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
    ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
  },
  paste = {
    ["+"] = "pbpaste",
    ["*"] = "pbpaste",
  },
}
