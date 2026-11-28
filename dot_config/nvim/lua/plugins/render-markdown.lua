return {
  "MeanderingProgrammer/render-markdown.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.icons" },
  ft = { "markdown" },
  opts = {},
  keys = {
    { "<leader>mp", "<cmd>RenderMarkdown toggle<cr>", ft = "markdown", desc = "Toggle Render Markdown" },
  },
}
