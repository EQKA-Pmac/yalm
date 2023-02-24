local configuration = require("yalm.config.configuration")

local function action(type, subcommands, global_settings, char_settings, args)
	local loot_subcommands = {
		subcommands = {},
	}

	for _, subcommand in pairs(global_settings.subcommands) do
		if subcommands[subcommand.trigger] then
			loot_subcommands.subcommands[subcommand.name] = subcommand
		end
	end

	Write.Help("\at[\ax\ay/yalm %s help\ax\at]\ax", type)

	configuration.print_type_help(loot_subcommands, "subcommands", type)
end

return { action_func = action }
