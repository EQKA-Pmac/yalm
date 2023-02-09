---@type Mq
local mq = require("mq")

local inventory = require("yalm.classes.inventory")
local evaluate = require("yalm.classes.evaluate")

local utils = require("yalm.lib.utils")

local looting = {}

looting.am_i_master_looter = function()
	return mq.TLO.Me.Name() == mq.TLO.Group.MasterLooter.Name()
end

looting.can_i_loot = function(loot_count_tlo)
	return mq.TLO.AdvLoot[loot_count_tlo]() > 0 and not mq.TLO.AdvLoot.LootInProgress()
end

looting.is_solo_looter = function()
	return mq.TLO.Group.Members() == nil or (mq.TLO.Group.Members() == 1 and mq.TLO.Me.Mercenary.ID())
end

looting.get_group_or_raid_tlo = function()
	local tlo = "Group"
	if mq.TLO.Raid.Members() > 0 then
		tlo = "Raid"
	end

	return tlo
end

looting.get_loot_tlos = function()
	local solo_looter = looting.is_solo_looter()
	local loot_count_tlo = solo_looter and "PCount" or "SCount"
	local loot_list_tlo = solo_looter and "PList" or "SList"

	return loot_count_tlo, loot_list_tlo
end

looting.get_loot_prefix = function()
	local solo_looter = looting.is_solo_looter()
	return solo_looter and "personal" or "shared"
end

looting.leave_item = function()
	local prefix = looting.get_loot_prefix()
	mq.cmdf("/advloot %s 1 leave", prefix)
end

looting.give_item = function(member)
	mq.cmdf("/advloot shared 1 giveto %s 1", member.Name())
end

looting.get_member_count = function(tlo)
	return mq.TLO[tlo].Members() or 0
end

looting.get_valid_member = function(tlo, index)
	local member = nil

	if index == 0 or mq.TLO[tlo].Member(index).Name() == mq.TLO.Me.CleanName() then
		member = mq.TLO.Me
	else
		member = mq.TLO[tlo].Member(index)
	end

	if member.ID() == 0 then
		return nil
	end

	return member
end

looting.get_member_can_loot = function(item, preference, save_slots, dannet_delay, always_loot)
	local group_or_raid_tlo = looting.get_group_or_raid_tlo()

	local can_loot = false
	local member = nil

	local count = looting.get_member_count(group_or_raid_tlo)

	for i = 0, (count - 1) do
		member = looting.get_valid_member(group_or_raid_tlo, i)

		if member then
			can_loot = evaluate.check_can_loot(member, item, preference, save_slots, dannet_delay, always_loot)

			if can_loot then
				break
			end
		end
	end

	return can_loot, member
end

looting.handle_master_looting = function(loot, settings, char_settings)
	if not looting.am_i_master_looter() then
		return
	end

	local loot_count_tlo, loot_list_tlo = looting.get_loot_tlos()

	if not looting.can_i_loot(loot_count_tlo) then
		return
	end

	local item = mq.TLO.AdvLoot[loot_list_tlo](1)
	local item_name = item.Name()

	if not item then
		return
	end

	local preference = evaluate.get_loot_preference(item, loot, char_settings, settings.unmatched_item_rule)

	if not preference then
		Write.Warn("No loot preference found for \a-t%s\ax", item_name)
		looting.leave_item()
		return
	end

	if not evaluate.is_valid_preference(loot.preferences, preference) then
		Write.Warn("Invalid loot preference for \a-t%s\ax", item_name)
		looting.leave_item()
		return
	end

	if loot.preferences[preference.setting].leave then
		Write.Info("Loot preference set to \aoleave\ax for \a-t%s\ax", item_name)
		looting.leave_item()
		return
	end

	Write.Info("\a-t%s\ax passes with %s", item_name, utils.GetItemPreferenceString(preference))

	local can_loot, member = looting.get_member_can_loot(item, preference, settings.save_slots, settings.dannet_delay)

	if not can_loot and settings.always_loot then
		Write.Warn("No one matched \a-t%s\ax loot preference", item_name)
		Write.Warn("Trying again ignoring quantity and list")
		can_loot, member = looting.get_member_can_loot(
			item,
			preference,
			settings.save_slots,
			settings.dannet_delay,
			settings.always_loot
		)
	end

	if not can_loot then
		Write.Warn("No one is able to loot \a-t%s\ax", item_name)
		looting.leave_item()
		return
	end

	if item_name == mq.TLO.AdvLoot[loot_list_tlo](1).Name() then
		Write.Info("Giving \a-t%s\ax to \ao%s\ax", item_name, member)
		looting.give_item(member)
		mq.doevents()
		mq.delay(settings.distribute_delay)
	end
end

looting.handle_personal_loot = function()
	local solo_looter = looting.is_solo_looter()

	if solo_looter then
		return
	end

	while mq.TLO.AdvLoot.PCount() > 0 do
		if not mq.TLO.AdvLoot.LootInProgress() and mq.TLO.AdvLoot.PList(1).Name() then
			Write.Info("Looting \a-t%s\ax", tostring(mq.TLO.AdvLoot.PList(1).Name()))
			inventory.check_lore_equip_prompt()
			mq.cmd("/advloot personal 1 loot")
			mq.delay(250)
		end
	end
end

return looting
