require 'core.keymaps'
require 'core.options'
require 'core.autocommands'

require('lazy').setup({
  require 'plugins.autopairs',
  require 'plugins.bufferline',
  require 'plugins.colorscheme',
  require 'plugins.completion',
  require 'plugins.conform',
  require 'plugins.gitsigns',
  require 'plugins.indent-blankline',
  require 'plugins.lsp',
  require 'plugins.lualine',
  require 'plugins.neo-tree',
  require 'plugins.nvim-treesitter',
  require 'plugins.telescope',
  require 'plugins.todo-comments',
  require 'plugins.vim-sleuth',
  require 'plugins.which-key',
}, {
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
