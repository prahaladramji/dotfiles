require 'core.keymaps'
require 'core.options'
require 'core.autocommands'

local has_work_plugins, work_plugins = pcall(require, 'plugins.work')

local plugins = {
  require 'plugins.autopairs',
  require 'plugins.bufferline',
  require 'plugins.colorscheme',
  require 'plugins.gitsigns',
  require 'plugins.indent-blankline',
  require 'plugins.lualine',
  require 'plugins.neo-tree',
  require 'plugins.notify',
  require 'plugins.nvim-treesitter',
  require 'plugins.todo-comments',
  require 'plugins.trouble',
  require 'plugins.vim-sleuth',
  require 'plugins.which-key',
}

if has_work_plugins then
  table.insert(plugins, work_plugins)
else
  vim.list_extend(plugins, {
    require 'plugins.completion',
    require 'plugins.conform',
    require 'plugins.lsp',
    require 'plugins.telescope',
  })
end

require('lazy').setup(plugins, {
  lockfile = vim.fn.stdpath 'config' .. (has_work_plugins and '/lazy-lock-work.json' or '/lazy-lock.json'),
  ui = {
    -- If you are using a Nerd Font: set icons to an empty table which will use the
    -- default lazy.nvim defined Nerd Font icons, otherwise define a unicode icons table
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
