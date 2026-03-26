-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

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
