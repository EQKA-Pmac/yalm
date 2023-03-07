---@type Mq
local mq = require("mq")
local PackageMan = require("mq/PackageMan")
local lfs = PackageMan.Require("luafilesystem", "lfs")

local loader = require("yalm.core.loader")

local utils = require("yalm.lib.utils")

local settings = {}

settings.get_char_settings_filename = function(character)
	local name = mq.TLO.Me.CleanName():lower()

	if character then
		name = character:lower()
	end

	return ("%s/YALM/yalm-%s-%s.lua"):format(mq.configDir, mq.TLO.EverQuest.Server(), name)
end

settings.get_default_char_settings_filename = function()
	return ("%s/yalm/config/defaults/char_settings.lua"):format(mq.luaDir)
end

settings.get_default_global_settings_filename = function()
	return ("%s/yalm/config/defaults/global_settings.lua"):format(mq.luaDir)
end

settings.get_default_yalm_settings_filename = function()
	return ("%s/yalm/config/defaults/yalm_settings.lua"):format(mq.luaDir)
end

settings.get_global_settings_filename = function()
	return ("%s/YALM.lua"):format(mq.configDir)
end

settings.init_char_settings = function(character)
	local char_settings = settings.load_char_settings(character)

	local default_copy = settings.load_default_char_settings()

	char_settings = utils.merge(default_copy, char_settings)

	return char_settings
end

settings.load_default_char_settings = function()
	local filename = settings.get_default_char_settings_filename()

	local module, error = loadfile(filename)()
	return module
end

settings.load_char_settings = function(character)
	local char_settings

	local filename = settings.get_char_settings_filename(character)

	if not utils.file_exists(filename) then
		char_settings = settings.load_default_char_settings()
		settings.save_char_settings(filename, char_settings)
	else
		local module, error = loadfile(filename)()
		char_settings = module
	end

	local timestamp, msg = lfs.attributes(filename, "modification")
	if not timestamp then
		Write.Warn("Error getting file modification: %s", msg)
	else
		char_settings.timestamp = timestamp
	end

	return char_settings
end

settings.init_global_settings = function()
	local global_settings = settings.load_global_settings()

	local default_copy = settings.load_default_global_settings()

	if global_settings.categories and type(global_settings.categories) == "table" then
		global_settings.categories = utils.table_concat(default_copy.categories, global_settings.categories)
	else
		global_settings.categories = default_copy.categories
	end

	if global_settings.commands and type(global_settings.commands) == "table" then
		global_settings.commands = utils.merge(default_copy.commands, global_settings.commands)
	else
		global_settings.commands = default_copy.commands
	end

	if global_settings.functions and type(global_settings.functions) == "table" then
		global_settings.functions = utils.merge(default_copy.functions, global_settings.functions)
	else
		global_settings.functions = default_copy.functions
	end

	if global_settings.preferences and type(global_settings.preferences) == "table" then
		global_settings.preferences = utils.merge(default_copy.preferences, global_settings.preferences)
	else
		global_settings.preferences = default_copy.preferences
	end

	if global_settings.rules and type(global_settings.rules) == "table" then
		global_settings.rules = utils.merge(default_copy.rules, global_settings.rules)
	else
		global_settings.settings = default_copy.settings
	end

	if global_settings.settings and type(global_settings.settings) == "table" then
		global_settings.settings = utils.merge(default_copy.settings, global_settings.settings)
	else
		global_settings.settings = default_copy.settings
	end

	if global_settings.subcommands and type(global_settings.subcommands) == "table" then
		global_settings.subcommands = utils.merge(default_copy.subcommands, global_settings.subcommands)
	else
		global_settings.subcommands = default_copy.subcommands
	end

	return global_settings
end

settings.load_default_global_settings = function()
	local filename = settings.get_default_global_settings_filename()

	local module, error = loadfile(filename)()
	return module
end

settings.load_default_yalm_settings = function()
	local filename = settings.get_default_yalm_settings_filename()

	local module, error = loadfile(filename)()
	return module
end

settings.load_global_settings = function()
	local global_settings

	local filename = settings.get_global_settings_filename()

	if not utils.file_exists(filename) then
		global_settings = settings.load_default_yalm_settings()
		settings.save_global_settings(filename, global_settings)
	else
		local module, error = loadfile(filename)()
		global_settings = module
	end

	local timestamp, msg = lfs.attributes(filename, "modification")

	if not timestamp then
		Write.Warn("Error getting file modification: %s", msg)
	else
		global_settings.timestamp = timestamp
	end

	return global_settings
end

settings.init_settings = function(character)
	assert(utils.make_dir(mq.configDir, "YALM"))

	local global_settings = settings.init_global_settings()
	local char_settings = settings.init_char_settings(character)

	if char_settings.settings then
		utils.merge(global_settings.settings, char_settings.settings)
	end

	return global_settings, char_settings
end

settings.reload_settings = function(global_settings, char_settings)
	local global_settings_timestamp = lfs.attributes(settings.get_global_settings_filename(), "modification")
	local char_settings_timestamp = lfs.attributes(settings.get_char_settings_filename(), "modification")

	if not global_settings_timestamp or not char_settings_timestamp then
		return global_settings, char_settings
	end

	local new_global_settings, new_char_settings

	if global_settings_timestamp > global_settings.timestamp or char_settings_timestamp > char_settings.timestamp then
		Write.Info("Reloading settings")
		new_global_settings, new_char_settings = settings.init_settings()
	else
		return global_settings, char_settings
	end

	if global_settings.categories and type(global_settings.categories) == "table" then
		new_global_settings.categories = utils.table_concat(new_global_settings.categories, global_settings.categories)
	end

	if global_settings.commands and type(global_settings.commands) == "table" then
		new_global_settings.commands = utils.merge(new_global_settings.commands, global_settings.commands)
	end

	if global_settings.functions and type(global_settings.functions) == "table" then
		new_global_settings.functions = utils.merge(new_global_settings.functions, global_settings.functions)
	end

	if global_settings.preferences and type(global_settings.preferences) == "table" then
		new_global_settings.preferences = utils.merge(new_global_settings.preferences, global_settings.preferences)
	end

	if global_settings.rules and type(global_settings.rules) == "table" then
		new_global_settings.rules = utils.merge(new_global_settings.rules, global_settings.rules)
	end

	if global_settings.settings and type(global_settings.settings) == "table" then
		new_global_settings.settings = utils.merge(new_global_settings.settings, global_settings.settings)
	end

	if global_settings.subcommands and type(global_settings.subcommands) == "table" then
		new_global_settings.subcommands = utils.merge(new_global_settings.subcommands, global_settings.subcommands)
	end

	return new_global_settings, new_char_settings
end

settings.save_global_settings = function(filename, global_settings)
	mq.pickle(filename, global_settings)
end

settings.save_char_settings = function(filename, char_settings)
	mq.pickle(filename, char_settings)
end

settings.remove_global_settings = function(loader_type, key)
	if not loader.types[loader_type] then
		Write.Error("%s is not a valid global key", loader_type)
		return
	end

	local global_settings = settings.load_global_settings()

	if type(key) == "number" then
		table.remove(global_settings[loader_type], key)
	else
		global_settings[loader_type][key] = nil
	end

	settings.save_global_settings(settings.get_global_settings_filename(), global_settings)
end

settings.set_global_settings = function(loader_type, tables)
	if not loader.types[loader_type] then
		Write.Error("%s is not a valid global key", loader_type)
		return
	end

	local global_settings = settings.load_global_settings()
	utils.merge(global_settings[loader_type], tables)

	settings.save_global_settings(settings.get_global_settings_filename(), global_settings)
end

settings.remove_and_save_global_settings = function(global_settings, loader_type, key)
	if not loader.types[loader_type] then
		Write.Error("%s is not a valid global key", loader_type)
		return
	end

	if type(key) == "number" then
		table.remove(global_settings[loader_type], key)
	else
		global_settings[loader_type][key] = nil
	end

	settings.remove_global_settings(loader_type, key)
end

settings.update_and_save_global_settings = function(global_settings, loader_type, tables)
	if not loader.types[loader_type] then
		Write.Error("%s is not a valid global key", loader_type)
		return
	end

	utils.merge(global_settings[loader_type], tables)
	settings.set_global_settings(loader_type, tables)
end

return settings
