-- LazyVim Extras (lazyvim.plugins.extras.coding.yanky) のキーマップに任せ、
-- カスタム動作（shada への履歴永続化 + システムクリップボードと履歴の同期）だけ上書き
return {
  "gbprod/yanky.nvim",
  opts = {
    ring = { storage = "shada" },
    system_clipboard = { sync_with_ring = true },
  },
}
