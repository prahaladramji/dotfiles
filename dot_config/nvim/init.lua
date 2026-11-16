require 'core.keymaps'
require 'core.options'
require 'core.autocommands'

local has_work_plugins, work_plugins = pcall(require, 'plugins.work')
local is_nas = (vim.uv or vim.loop).fs_stat '/etc/synoinfo.conf' ~= nil
local has_cc = not is_nas and (vim.fn.executable 'cc' == 1 or vim.fn.executable 'gcc' == 1 or vim.fn.executable 'clang' == 1)
vim.g.has_cc = has_cc

local plugins = {
  require 'plugins.autopairs',
  require 'plugins.bufferline',
  require 'plugins.colorscheme',
  require 'plugins.gitsigns',
  require 'plugins.indent-blankline',
  require 'plugins.lualine',
  require 'plugins.neo-tree',
  require 'plugins.notify',
  require 'plugins.todo-comments',
  require 'plugins.trouble',
  require 'plugins.vim-sleuth',
  require 'plugins.which-key',
}

if has_cc then
  table.insert(plugins, require 'plugins.nvim-treesitter')
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
end

local lockfile = vim.fn.stdpath 'config' .. (has_work_plugins and '/lazy-lock-work.json' or '/lazy-lock.json')
if not has_cc then
  local state_lockfile = vim.fn.stdpath 'state' .. '/lazy-lock.json'
  if not (vim.uv or vim.loop).fs_stat(state_lockfile) and (vim.uv or vim.loop).fs_stat(lockfile) then
    vim.fn.mkdir(vim.fn.stdpath 'state', 'p')
    vim.fn.writefile(vim.fn.readfile(lockfile), state_lockfile)
  end
  lockfile = state_lockfile
end

require('lazy').setup(plugins, {
  lockfile = lockfile,
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
