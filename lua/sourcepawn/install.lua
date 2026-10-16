local sp = require('sourcepawn')

local M = {}

local SERVER_RELEASES = 'https://github.com/Sarrus1/sourcepawn-studio/releases/download'
local SOURCEMOD_RELEASES = 'https://github.com/alliedmodders/sourcemod/releases/download'

-- uname values mapped to the names used in sourcepawn-studio's release files
local SYSTEMS = { Linux = 'linux', Darwin = 'darwin', Windows_NT = 'windows' }
local ARCHES = { x86_64 = 'amd64', aarch64 = 'arm64', arm64 = 'arm64', armv7l = 'armv7' }

local function notify(msg, level)
  vim.notify('sourcepawn: ' .. msg, level or vim.log.levels.INFO)
end

---@return string system, string arch
local function platform()
  local uname = vim.uv.os_uname()
  local system, arch = SYSTEMS[uname.sysname], ARCHES[uname.machine]
  if not system or not arch then
    error(('no sourcepawn-studio build for %s %s'):format(uname.sysname, uname.machine), 0)
  end
  return system, arch
end

--- Runs a command without blocking the editor. Must be called inside a coroutine.
---@param cmd string[]
---@return string stdout
local function run(cmd)
  local co = coroutine.running()
  vim.system(cmd, { text = true }, vim.schedule_wrap(function(result)
    coroutine.resume(co, result)
  end))
  local result = coroutine.yield() ---@type vim.SystemCompleted
  if result.code ~= 0 then
    error(('%s failed: %s'):format(cmd[1], vim.trim(result.stderr)), 0)
  end
  return result.stdout
end

--- Fetches a URL, saving it to `outpath` if given. Must be called inside a coroutine.
---@param url string
---@param outpath? string
---@return string body Empty when saved to `outpath`.
local function fetch(url, outpath)
  local co = coroutine.running()
  vim.net.request(url, { outpath = outpath }, vim.schedule_wrap(function(err, response)
    coroutine.resume(co, err, response)
  end))
  local err, response = coroutine.yield()
  if err then
    error(('download of %s failed: %s'):format(url, vim.trim(err)), 0)
  end
  return response.body
end

--- Windows' own tar is bsdtar, which reads zips. Prefer it over a GNU tar from MSYS2 or
--- Cygwin earlier in PATH, which can't.
local function tar()
  if vim.fn.has('win32') == 1 then
    local system_tar = vim.fs.joinpath(vim.env.SystemRoot or 'C:/Windows', 'System32', 'tar.exe')
    if vim.uv.fs_stat(system_tar) then
      return system_tar
    end
  end
  return 'tar'
end

-- tar picks the archive format from the file itself.
local function extract(archive, dest, member)
  vim.fn.mkdir(dest, 'p')
  run({ tar(), '-xf', archive, '-C', dest, member })
end

local function install_server(system, arch, tmp)
  local tag = sp.config.server_version
  local ext = system == 'windows' and 'zip' or 'tar.gz'
  local name = ('sourcepawn-studio-%s-%s-%s.%s'):format(tag, system, arch, ext)
  local archive = vim.fs.joinpath(tmp, name)
  fetch(('%s/%s/%s'):format(SERVER_RELEASES, tag, name), archive)

  local path = sp.server_path()
  extract(archive, vim.fs.dirname(path), vim.fs.basename(path))
  -- The Linux builds ship with full debug info; stripping takes them from ~250 MB to ~18 MB.
  if system == 'linux' and vim.fn.executable('strip') == 1 then
    run({ 'strip', path })
  end
end

--- Installs SourceMod's scripting folder, or only its includes where SourceMod has no
--- compiler build. The includes are the same on every platform.
---@return boolean has_compiler
local function install_sourcemod(system, arch, tmp)
  local version = sp.config.sourcemod_version
  -- Release 1.12.0.7255 ships as sourcemod-1.12.0-git7255-linux.tar.gz
  local release, build = version:match('^(%d+%.%d+%.%d+)%.(%d+)$')
  if not release then
    error(('sourcemod_version should look like 1.12.0.7255, got %q'):format(version), 0)
  end
  local windows = system == 'windows'
  local has_compiler = windows or (system == 'linux' and arch == 'amd64')
  local name = ('sourcemod-%s-git%s-%s'):format(release, build, windows and 'windows.zip' or 'linux.tar.gz')
  local archive = vim.fs.joinpath(tmp, name)
  fetch(('%s/%s/%s'):format(SOURCEMOD_RELEASES, version, name), archive)

  local dest = vim.fs.joinpath(sp.data_dir(), 'sourcemod')
  vim.fn.delete(dest, 'rf')
  local member = 'addons/sourcemod/scripting' .. (has_compiler and '' or '/include')
  extract(archive, dest, member)
  return has_compiler
end

--- Points the LSP config and open SourcePawn buffers at the new install.
local function reload()
  -- Re-enabling drops the cached config, so lsp/sourcepawn_studio.lua runs again.
  vim.lsp.enable('sourcepawn_studio')
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].filetype == 'sourcepawn' then
      -- Setting the filetype re-runs the ftplugins and the LSP attach for the buffer.
      vim.bo[buf].filetype = 'sourcepawn'
    end
  end
end

--- Downloads sourcepawn-studio and SourceMod's scripting folder into
--- `require('sourcepawn').data_dir()`. Runs in the background.
function M.install()
  coroutine.wrap(function()
    local tmp = vim.fn.tempname()
    vim.fn.mkdir(tmp, 'p')
    local ok, err = pcall(function()
      local system, arch = platform()
      notify(('downloading sourcepawn-studio %s for %s-%s'):format(sp.config.server_version, system, arch))
      install_server(system, arch, tmp)
      notify(('downloading SourceMod %s'):format(sp.config.sourcemod_version))
      if not install_sourcemod(system, arch, tmp) then
        notify(
          ('SourceMod has no compiler for %s-%s, so only its includes were installed. '
            .. 'To compile, set scripting_dir to a folder with spcomp.'):format(system, arch),
          vim.log.levels.WARN
        )
      end
    end)
    vim.fn.delete(tmp, 'rf')
    if ok then
      reload()
      notify('done')
    else
      notify(err, vim.log.levels.ERROR)
    end
  end)()
end

return M
