local M = {}

function M.check()
  local sp = require('sourcepawn')
  local uname = vim.uv.os_uname()
  vim.health.start('sourcepawn.nvim')
  vim.health.info(('Platform: %s %s'):format(uname.sysname, uname.machine))

  local server = sp.server()
  if vim.fn.executable(server) == 1 then
    vim.health.ok('sourcepawn-studio: ' .. vim.fn.exepath(server))
  else
    vim.health.error('sourcepawn-studio not found', 'Run :SourcePawnInstall or put it on PATH')
  end

  local dir = sp.scripting_dir()
  if not dir then
    vim.health.error(
      'No SourceMod scripting folder',
      'Set scripting_dir in setup() or run :SourcePawnInstall'
    )
    return
  end
  vim.health.ok('Scripting folder: ' .. dir)

  local compiler = sp.compiler()
  if compiler then
    vim.health.ok('Compiler: ' .. compiler)
  else
    vim.health.warn(
      'No spcomp64 or spcomp in ' .. dir .. '; :make and compiler diagnostics are off',
      'Set scripting_dir in setup() to a SourceMod scripting folder with a compiler'
    )
  end

  if vim.uv.fs_stat(vim.fs.joinpath(dir, 'include', 'sourcemod.inc')) then
    vim.health.ok('Includes: ' .. vim.fs.joinpath(dir, 'include'))
  else
    vim.health.error('No include/sourcemod.inc in ' .. dir)
  end
end

return M
