# telescope-doit.nvim

Doit is an extension for the [telescope
plugin](https://github.com/nvim-telescope/telescope.nvim). It provides a single
picker for searching an listing out TODO/FIXME's in your files.

## Install and getting started

**VimPlug**
```vimscript
"" requirement for telescope-doit
Plug "nvim-telescope/telescope.nvim"
Plug "calder-ty/telescope-doit.nvim"
```

Getting started, you can simply map the picker with:
```vimscript
:nnoreamp <leader><leader>t :lua require("telescope-doit").doit()<cr>
```

## Setup
You can modify what values are searched for by passing a table of search terms
to the picker. Each key represents a new search term, and the value is a table
of optional configuration options. For example to search for the terms:
"TODO:", "BUG:" and "FIXME:", you can add the following:

```lua
require("telescope-doit").doit({searches = {
	["TODO:"] = { symbol = '✓'}, 
	["FIXME:"] = {symbol = "⚠"}, 
	["BUG:"] = {symbol = "X"}
}})
```

### Configuration

The following are the options that can be applied for each search term:

- symbol:  A symbol that will be used to identify the type of task/note found,
		defaults to '✓'


