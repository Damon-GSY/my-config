return {
  {
    "MagicDuck/grug-far.nvim",
    keys = {
      {
        "<leader>sf",
        function()
          require("grug-far").open({
            prefills = {
              paths = vim.fn.expand("%:p"),
            },
          })
        end,
        desc = "Search and replace in current file",
      },
    },
  },
}
