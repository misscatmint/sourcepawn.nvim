vim.bo.commentstring = '// %s'
-- Does nothing when the sourcepawn treesitter parser isn't installed.
pcall(vim.treesitter.start)
vim.b.undo_ftplugin = 'setlocal commentstring< makeprg< errorformat<'
  .. ' | call v:lua.vim.treesitter.stop()'

local compiler = require('sourcepawn').compiler()
if compiler then
  vim.bo.makeprg = vim.fn.shellescape(compiler) .. ' %:S'
  vim.bo.errorformat = '%f(%l) : %trror %n: %m,%f(%l) : %tarning %n: %m,%-G%.%#'
end
