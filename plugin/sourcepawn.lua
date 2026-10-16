vim.filetype.add({
  extension = { sp = 'sourcepawn' },
  pattern = { ['.*/include/.*%.inc'] = 'sourcepawn' },
})

vim.api.nvim_create_user_command('SourcePawnInstall', function()
  require('sourcepawn.install').install()
end, { desc = 'Download sourcepawn-studio and SourceMod' })

vim.lsp.enable('sourcepawn_studio')
