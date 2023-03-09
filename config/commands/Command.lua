local configuration = require("yalm.config.configuration")

local valid_subcommands = {
	help = {},
	create = {},
	delete = {},
	edit = {},
	list = {},
	set = {},
}

local function action(global_settings, char_settings, args)
	configuration.action(valid_subcommands, global_settings, char_settings, configuration.types.command.name, args)
end

return { action_func = action }
