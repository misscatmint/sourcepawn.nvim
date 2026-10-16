local M = {}

local EXE = vim.fn.has('win32') == 1 and '.exe' or ''

---@class sourcepawn.Config
---@field scripting_dir? string Folder containing spcomp and include/. Defaults to the one :SourcePawnInstall downloads.
---@field sourcemod_version string SourceMod release :SourcePawnInstall downloads, e.g. '1.12.0.7255'.
---@field server_version string sourcepawn-studio release tag :SourcePawnInstall downloads.

---@type sourcepawn.Config
M.config = {
  sourcemod_version = '1.12.0.7255',
  server_version = 'v8.1.8',
}

--- Overrides the defaults in `M.config`. Calling it is optional.
---@param opts? sourcepawn.Config
function M.setup(opts)
  M.config = vim.tbl_extend('force', M.config, opts or {})
end

--- Folder that :SourcePawnInstall downloads into.
---@return string
function M.data_dir()
  return vim.fs.joinpath(vim.fn.stdpath('data'), 'sourcepawn')
end

--- Folder containing spcomp and include/, or nil if it doesn't exist.
---@return string?
function M.scripting_dir()
  local dir = M.config.scripting_dir
    or vim.fs.joinpath(M.data_dir(), 'sourcemod', 'addons', 'sourcemod', 'scripting')
  return vim.uv.fs_stat(dir) and dir or nil
end

--- Path to spcomp in the scripting folder, preferring the 64-bit build.
---@return string?
function M.compiler()
  local dir = M.scripting_dir()
  if not dir then
    return nil
  end
  for _, name in ipairs({ 'spcomp64', 'spcomp' }) do
    local path = vim.fs.joinpath(dir, name .. EXE)
    if vim.uv.fs_stat(path) then
      return path
    end
  end
  return nil
end

--- Where :SourcePawnInstall puts sourcepawn-studio.
---@return string
function M.server_path()
  return vim.fs.joinpath(M.data_dir(), 'bin', 'sourcepawn-studio' .. EXE)
end

--- Command for sourcepawn-studio: the downloaded binary if present, otherwise the one on PATH.
---@return string
function M.server()
  local path = M.server_path()
  return vim.uv.fs_stat(path) and path or 'sourcepawn-studio'
end

return M
