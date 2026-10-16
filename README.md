# sourcepawn.nvim

SourcePawn support for Neovim:

- `:SourcePawnInstall` downloads sourcepawn-studio and SourceMod.
- `.sp` files (and `.inc` files under an `include/` folder) get the
  `sourcepawn` filetype.
- Treesitter highlighting starts automatically when the `sourcepawn` parser is
  installed.
- [sourcepawn-studio](https://github.com/Sarrus1/sourcepawn-studio) runs as
  the language server, with SourceMod's includes and compiler wired in.
- `:make` compiles the current file with spcomp and fills the quickfix list.

## Requirements

- Neovim 0.12+.
- `curl` and `tar` for `:SourcePawnInstall`. Windows 10 and later include
  both.

## Install

```lua
vim.pack.add({ 'https://github.com/misscatmint/sourcepawn.nvim' })
```

Then run `:SourcePawnInstall` once and check `:checkhealth sourcepawn`. The
full reference is in `:help sourcepawn`.

## Syntax highlighting

Highlighting comes from the `sourcepawn` treesitter parser. With
[nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter):

```lua
require('nvim-treesitter').install({ 'sourcepawn' })
```

## Configuration

`setup()` is optional. The defaults:

```lua
require('sourcepawn').setup({
  -- Folder containing spcomp and include/. Defaults to the SourceMod
  -- downloaded by :SourcePawnInstall.
  scripting_dir = nil,
  -- SourceMod release :SourcePawnInstall downloads, as listed on
  -- https://github.com/alliedmodders/sourcemod/releases
  sourcemod_version = '1.12.0.7255',
  -- sourcepawn-studio release :SourcePawnInstall downloads.
  server_version = 'v8.1.8',
})
```

To use your own SourceMod build or release instead, point `scripting_dir` at
its scripting folder, for example `addons/sourcemod/scripting` in a release or
`package` in a `configure.py --scripting-only` build.

## Platforms

| Platform              | sourcepawn-studio | SourceMod             |
| --------------------- | ----------------- | --------------------- |
| Linux x86_64          | downloaded        | compiler and includes |
| Windows x86_64, arm64 | downloaded        | compiler and includes |
| Linux arm64, armv7    | downloaded        | includes only         |
| macOS                 | downloaded        | includes only         |

SourceMod only publishes compilers for Linux x86 and Windows. Elsewhere the
includes still give you completion, hover and go-to-definition. To compile,
point `scripting_dir` at a scripting folder with spcomp built for your
platform.

## Notes

- The language server uses the nearest `.git` folder as the project root.
  Outside a git repo it still works for the file you're editing, but won't
  load the rest of the project.
- `:make` writes the `.smx` file to Neovim's current directory.

## License

MIT.
