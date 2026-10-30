return {
  'rcarriga/nvim-notify',
  init = function()
    vim.opt.termguicolors = true
  end,
  cmd = 'Notifications',
  opts = {
    background_colour = '#000000',
  },
}
