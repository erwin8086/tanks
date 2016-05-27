tanks.register_on_update(function(pos, meta)
	local content = meta:get_int("content")
	print("Tank on pos:"..pos.y.." updates content="..content)
end)

tanks.register_on_place(function(pos, placer, itemstack, pt)
	local sm = minetest.deserialize(itemstack:get_metadata())
	if sm ~= nil then
		print("Tank placed on "..pos.y.." by "..placer:get_player_name().." content="..sm.content)
	end
end)

tanks.register_on_dig(function(pos, node, player)
	print("Tank on "..pos.y.."digged by "..player:get_player_name())
end)

tanks.register_on_punch(function(pos, node, player, itemstack, pt)
	print("Tank on "..pos.y.." punched by "..player:get_player_name().." with item "..itemstack:get_name())
end)

tanks.register_on_rightclick(function(pos, node, player, itemstack, pt)
	print("Tank on "..pos.y.." rightclicked by "..player:get_player_name().." with item "..itemstack:get_name())
end)