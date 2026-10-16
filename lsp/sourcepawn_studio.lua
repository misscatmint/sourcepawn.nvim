local sp = require('sourcepawn')
local dir = sp.scripting_dir()

return {
  cmd = { sp.server() },
  filetypes = { 'sourcepawn' },
  root_markers = { '.git' },
  settings = {
    SourcePawnLanguageServer = {
      compiler = { path = sp.compiler() },
      includeDirectories = { dir and vim.fs.joinpath(dir, 'include') },
    },
  },
}
