return {
  'sainnhe/everforest',
  lazy = false,
  priority = 1000, -- Make sure to load this before all the other start plugins.
  config = function()
    vim.o.background = 'dark'
    vim.g.everforest_background = 'hard'
    vim.g.everforest_disable_italic_comment = 1
    vim.g.everforest_better_performance = 1

    vim.cmd.colorscheme 'everforest'
  end,
}
