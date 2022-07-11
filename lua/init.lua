local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local utils = require "telescope.utils"
local Path = require "plenary.path"
local conf = require("telescope.config").values

local flatten = vim.tbl_flatten
local M = {}
local make_entry = {}
local handle_entry_index = function(opts, t, k)
  local override = ((opts or {}).entry_index or {})[k]
  if not override then
    return
  end

  local val, save = override(t, opts)
  if save then
    rawset(t, k, val)
  end
  return val
end
do
  local lookup_keys = {
    value = 1,
    ordinal = 1,
  }

  -- Gets called only once to parse everything out for the vimgrep, after that looks up directly.
  local parse_with_col = function(t)
    local _, _, filename, lnum, col, text = string.find(t.value, [[(..-):(%d+):(%d+):(.*)]])

    local ok
    ok, lnum = pcall(tonumber, lnum)
    if not ok then
      lnum = nil
    end

    ok, col = pcall(tonumber, col)
    if not ok then
      col = nil
    end

    t.filename = filename
    t.lnum = lnum
    t.col = col
    t.text = text

    return { filename, lnum, col, text }
  end

  local parse_without_col = function(t)
    local _, _, filename, lnum, text = string.find(t.value, [[(..-):(%d+):(.*)]])

    local ok
    ok, lnum = pcall(tonumber, lnum)
    if not ok then
      lnum = nil
    end

    t.filename = filename
    t.lnum = lnum
    t.col = nil
    t.text = text

    return { filename, lnum, nil, text }
  end

  function make_entry.gen_from_vimgrep(opts)
    opts = opts or {}

    local mt_vimgrep_entry
    local parse = parse_with_col
    if opts.__inverted == true then
      parse = parse_without_col
    end

    local disable_devicons = opts.disable_devicons
    local disable_coordinates = opts.disable_coordinates
    local only_sort_text = opts.only_sort_text

    local execute_keys = {
      path = function(t)
        if Path:new(t.filename):is_absolute() then
          return t.filename, false
        else
          return Path:new({ t.cwd, t.filename }):absolute(), false
        end
      end,

      filename = function(t)
        return parse(t)[1], true
      end,

      lnum = function(t)
        return parse(t)[2], true
      end,

      col = function(t)
        return parse(t)[3], true
      end,

      text = function(t)
        return parse(t)[4], true
      end,

    }

    -- For text search only, the ordinal value is actually the text.
    if only_sort_text then
      execute_keys.ordinal = function(t)
        return t.text
      end
    end

    local display_string = "%s:%s %s"

    mt_vimgrep_entry = {
      cwd = vim.fn.expand(opts.cwd or vim.loop.cwd()),
	  searches = opts.searches,

      display = function(entry)
        local display_filename = utils.transform_path(opts, entry.filename)
        local coordinates = ""
		local display_string = '%s %s'

        if not opts.disable_coordinates then
          if entry.col then
            coordinates = string.format("%s:%s:", entry.lnum, entry.col)
          else
            coordinates = string.format("%s:", entry.lnum)
          end
        end
		local value = string.format("%s:%s%s", display_filename, coordinates, entry.text:gsub("^%s+", ""))
		local kind
		for search, _ in pairs(opts.searches) do
			_, _, kind = string.find(entry.text, "(".. search ..")")
			if kind then
				break
			end
		end

		icon_mapping = function(key)
			local t = opts.searches or {}
			return (t[key] or {}).symbol or '✓'
		end

		type_ = icon_mapping(kind) or '✓'

        return string.format(display_string, type_, value)
	end,

      __index = function(t, k)
        local override = handle_entry_index(opts, t, k)
        if override then
          return override
        end

        local raw = rawget(mt_vimgrep_entry, k)
        if raw then
          return raw
        end

        local executor = rawget(execute_keys, k)
        if executor then
          local val, save = executor(t)
          if save then
            rawset(t, k, val)
          end
          return val
        end

        return rawget(t, rawget(lookup_keys, k))
      end,
    }

    return function(line)
      return setmetatable({ line }, mt_vimgrep_entry)
    end
  end
end

-- References the "grep_string" function from telescope
M.doit = function(opts)
	opts = opts or {}

	opts.cwd = opts.cwd and vim.fn.expand(opts.cwd) or vim.loop.cwd()
	local vimgrep_arguments = opts.vimgrep_arguments or conf.vimgrep_arguments
	local searches = opts.searches or {["TODO:"] = { symbol = '✓'}, ["FIXME:"] = {symbol = "⚠"}, ["BUG:"] = {symbol = "X"} }

	local keys = {}
	local i = 1
	for k, v in pairs(searches) do
		keys[i] = k
		i = i + 1
	end

	local search = { "--", table.concat(keys, '|')}

	local additional_args = {}
	if opts.additional_args ~= nil and type(opts.additional_args) == "function" then
		additional_args = opts.additional_args(opts)
	end

	local args = flatten {
		vimgrep_arguments,
		additional_args,
		{use_regex=true},
		search,
	}

	opts.entry_maker = opts.entry_maker or make_entry.gen_from_vimgrep(opts)
	pickers.new(opts, {
		prompt_title = "Just Do It",
		finder = finders.new_oneshot_job(args, opts),
		previewer = conf.grep_previewer(opts),
		sorter = conf.generic_sorter(opts),
		preview_title = "",

	}):find()
end


-- M.doit()
return M

