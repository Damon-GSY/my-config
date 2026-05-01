-- every spec file under the "plugins" directory will be loaded automatically by lazy.nvim
--
-- In your plugin files, you can:
-- * add extra plugins
-- * disable/enabled LazyVim plugins
-- * override the configuration of LazyVim plugins
return {
  "chentoast/marks.nvim",
  event = "VeryLazy",
  opts = { default_mappings = false },
  keys = {
    { "<leader>mm", "<Plug>(Marks-toggle)", mode = "n", desc = "Toggle mark" }, -- 切换当前行标记
    { "<leader>ma", "<Plug>(Marks-set)", mode = "n", desc = "Set letter mark" }, -- 设定字母标记
    { "<leader>md", "<Plug>(Marks-delete)", mode = "n", desc = "Delete letter mark" }, -- 删除字母标记
    { "<leader>mD", "<Plug>(Marks-deletebuf)", mode = "n", desc = "Delete marks (buf)" }, -- 清空当前缓冲区标记
    { "<leader>mn", "<Plug>(Marks-next)", mode = "n", desc = "Next mark" }, -- 下一个标记
    { "<leader>mp", "<Plug>(Marks-prev)", mode = "n", desc = "Prev mark" }, -- 上一个标记
    { "<leader>m:", "<Plug>(Marks-preview)", mode = "n", desc = "Preview mark" }, -- 预览标记
    { "<leader>ml", ":MarksListBuf<CR>", mode = "n", desc = "List marks (buf)" }, -- 列出当前缓冲区标记
    { "<leader>mL", ":MarksListAll<CR>", mode = "n", desc = "List marks (all)" }, -- 列出所有打开缓冲区标记
  },
}
