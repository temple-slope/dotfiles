return {
  "mg979/vim-visual-multi",
  branch = "master",
  lazy = false, -- 常に読み込む
  init = function()
    -- VSCode 風 Cmd+D: WezTerm が <C-A-d> として送ってくる
    -- Cmd+Shift+A: V 選択した各行末にカーソル（<C-A-a> として受信）
    vim.g.VM_maps = {
      ["Find Under"] = "<C-A-d>",
      ["Find Subword Under"] = "<C-A-d>",
      ["Visual Add"] = "<C-A-a>",
    }
  end,
}
