-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- jj で Insert モードから抜ける
vim.keymap.set("i", "jj", "<Esc>", { desc = "Escape insert mode" })

-- Copy relative file path
vim.keymap.set("n", "<leader>yp", function()
  local path = vim.fn.fnamemodify(vim.fn.expand("%"), ":~:.")
  vim.fn.setreg("+", path)
  vim.notify("Copied: " .. path)
end, { desc = "Copy relative file path" })

-- Copy absolute file path
vim.keymap.set("n", "<leader>yP", function()
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  vim.notify("Copied: " .. path)
end, { desc = "Copy absolute file path" })

-- Copy file path with line number
vim.keymap.set("n", "<leader>yl", function()
  local path = vim.fn.fnamemodify(vim.fn.expand("%"), ":~:.")
  local line = vim.fn.line(".")
  local result = path .. ":" .. line
  vim.fn.setreg("+", result)
  vim.notify("Copied: " .. result)
end, { desc = "Copy file path with line number" })

-- Split window (match tmux: prefix+- / prefix+_)
vim.keymap.set("n", "<leader>-", "<C-W>s", { desc = "Split Below" })
vim.keymap.set("n", "<leader>_", "<C-W>v", { desc = "Split Right" })

-- Copy GitHub permalink (via snacks.gitbrowse)
vim.keymap.set({ "n", "v" }, "<leader>gy", function()
  Snacks.gitbrowse({
    open = function(url)
      vim.fn.setreg("+", url)
      vim.notify("Copied: " .. url)
    end,
  })
end, { desc = "Copy GitHub permalink" })

-- VSCode 風: Cmd+P → ファイル検索（WezTerm 経由で <C-A-p> として受信）
vim.keymap.set({ "n", "i" }, "<C-A-p>", function()
  Snacks.picker.files()
end, { desc = "Find Files (Cmd+P)" })

-- Cmd+F → プロジェクト内ファイル内容を grep 検索（WezTerm 経由で <C-A-f> として受信）
vim.keymap.set({ "n", "i" }, "<C-A-f>", function()
  Snacks.picker.grep()
end, { desc = "Grep in Project (Cmd+F)" })

-- VSCode 風: Cmd+Shift+P → コマンドパレット（<C-A-c>）
vim.keymap.set({ "n", "i" }, "<C-A-c>", function()
  Snacks.picker.commands()
end, { desc = "Command Palette (Cmd+Shift+P)" })

-- VSCode 風: Cmd+/ → コメントトグル（<C-A-/>）
vim.keymap.set("n", "<C-A-/>", "gcc", { desc = "Toggle Comment (Cmd+/)", remap = true })
vim.keymap.set("v", "<C-A-/>", "gc", { desc = "Toggle Comment (Cmd+/)", remap = true })
vim.keymap.set("i", "<C-A-/>", "<Esc>gcca", { desc = "Toggle Comment (Cmd+/)", remap = true })

-- VSCode 風: Cmd+W → バッファだけ閉じる（ウィンドウレイアウト保持）
vim.keymap.set({ "n", "i" }, "<C-A-w>", function()
  Snacks.bufdelete()
end, { desc = "Delete Buffer (Cmd+W)" })

-- Ctrl+Shift+H/L でバッファ前後移動（WezTerm 経由で <C-A-h>/<C-A-l> として受信）
vim.keymap.set({ "n", "i" }, "<C-A-h>", "<cmd>bprevious<cr>", { desc = "Prev Buffer (Ctrl+Shift+H)" })
vim.keymap.set({ "n", "i" }, "<C-A-l>", "<cmd>bnext<cr>", { desc = "Next Buffer (Ctrl+Shift+L)" })
