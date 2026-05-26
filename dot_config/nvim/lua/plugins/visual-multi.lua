return {
  "mg979/vim-visual-multi",
  branch = "master",
  lazy = false, -- 常に読み込む
  init = function()
    -- VSCode 風 Cmd+D: WezTerm が <C-A-d> として送ってくる
    vim.g.VM_maps = {
      ["Find Under"] = "<C-A-d>",
      ["Find Subword Under"] = "<C-A-d>",
    }
  end,
}
