--[[
	Liquid tanks for minetest
	By erwin8086
--]]

tanks = {}
tanks.reg = {}

dofile(minetest.get_modpath("tanks").."/api.lua")

--[[
	Update tank outfit and infotext
]]
local function update_tank(pos, meta)
	if tanks.on_update(pos, meta) then
		return
	end
	local type = meta:get_string("type")
	local content = meta:get_int("content")
	if type == "empty" then
		minetest.swap_node(pos, {name="tanks:tank"})
		meta:set_string("infotext", "Tank: empty")
	end
	local i = math.floor(content/1000)
	meta:set_string("infotext", "Tank: "..type.." "..content.."mB")
	if i == 0 then
		minetest.swap_node(pos, {name="tanks:tank"})
	else
		minetest.swap_node(pos, {name="tanks:tank_"..type.."_"..i})
	end
end

--[[
	Place tank
	Called by after_place_node
]]
local function place_tank(pos, placer, itemstack, pt)
	if tanks.on_place(pos, placer, itemstack, pt) then
		return
	end
	local meta = minetest.get_meta(pos)
	local sm = minetest.deserialize(itemstack:get_metadata())
	if sm ~= nil then
		meta:set_int("content", sm.content)
		meta:set_string("type", sm.type)
	else
		meta:set_int("content", 0)
		meta:set_string("type", "empty")
	end
	update_tank(pos, meta)
end

--[[
	Dig the tank
	Called by on_dig
	check diggable and can_dig
	calls    after_dig_node and global on_dignode
]]
local function dig_tank(pos, node, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		minetest.record_protection_violation(pos, player:get_player_name())
		return
	end
	if tanks.on_dig(pos, node, player) then
		return
	end
	local def = minetest.registered_nodes[node.name]
	if def.diggable == false then
		return
	end
	if def.can_dig ~= nil then
		if def.can_dig(pos,player) == false then
			return
		end
	end
	local item = player:get_wielded_item()
	item:add_wear(1)
	player:set_wielded_item(item)

	local drop = ItemStack(node.name)
	local meta = minetest.get_meta(pos)
	local sm = {}
	sm.type  = meta:get_string("type")
	sm.content = meta:get_int("content")
	drop:set_metadata(minetest.serialize(sm))

	local inv = player:get_inventory()
	if inv:room_for_item("main", drop) then
		inv:add_item("main", drop)
	else
		minetest.item_drop(drop, player, player:getpos())
	end
	minetest.remove_node(pos)

	if def.after_dig_node ~= nil then
		def.after_dig_node(pos, node, oldmeta, player)
	end
	for _, callback in ipairs(minetest.registered_on_dignodes) do
		if callback ~= nill then
			callback(pos, node, player)
		end
	end
end

--[[
	Called when Player punch a tank
]]
local function punch_tank(pos, node, player, pt)
	if minetest.is_protected(pos, player:get_player_name()) then
		minetest.record_protection_violation(pos, player:get_player_name())
		return
	end
	local item = player:get_wielded_item()
	local on_punch = tanks.on_punch(pos, node, player, item, pt)
	if on_punch then
		return on_punch
	end
	if item:get_name() == "bucket:bucket_empty" then
		local meta = minetest.get_meta(pos)
		local name = meta:get_string("type")
		if name ~= "empty" then
			local content = meta:get_int("content")
			if content >= 1000 then
				content = content - 1000
				meta:set_int("content", content)
				if content == 0 then
					meta:set_string("type", "empty")
				end
				update_tank(pos, meta)
				if item:get_count() > 1 then
					item:take_item()
					local inv = player:get_inventory()
					if inv:room_for_item("main", tanks.reg[name].bucket) then
						inv:add_item("main", tanks.reg[name].bucket)
					else
						minetest.item_drop(ItemStack(tanks.reg[name].bucket), player, player:getpos())
					end
					return item
				else
					return ItemStack(tanks.reg[name].bucket)
				end
			end
		end
	end
	
end

local bucket_use = minetest.registered_items["bucket:bucket_empty"].on_use

--[[
	Call punch tank when player use a bucket
]]
minetest.override_item("bucket:bucket_empty", {
	on_use = function(stack, player, pt)
		if pt.type == "node" then
			local node = minetest.get_node_or_nil(pt.under)
			if node ~= nil then
				if minetest.get_node_group(node.name, "tank") == 1 then
					return punch_tank(pt.under, node, player, pt)
				end
			end
		end
		return bucket_use(stack, player, pt)
	end
})

--[[
	Get definition by name of bucket item
]]
local function get_def_by_bucket(bucket)
	for name, def in pairs(tanks.reg) do
		if def.bucket == bucket then
			return name, def
		end
	end
end

-- Makes it avilable for other mods
tanks.get_def_by_bucket = get_def_by_bucket

--[[
	Called when player rightclicks a tank
]]
local function on_rightclick(pos, node, player, itemstack, pt)
	if minetest.is_protected(pos, player:get_player_name()) then
		minetest.record_protection_violation(pos, player:get_player_name())
		return
	end
	local on_rightclick = tanks.on_rightclick(pos, node, player, itemstack, pt) 
	if on_rightclick then
		return on_rightclick
	end
	local bucket = itemstack:get_name()
	local name, def = get_def_by_bucket(bucket)
	if name == nil then
		return itemstack
	end
	local meta = minetest.get_meta(pos)
	local liquid = meta:get_string("type")
	if liquid == "empty" then
		meta:set_int("content", 1000)
		meta:set_string("type", name)
		itemstack = ItemStack("bucket:bucket_empty")
	elseif liquid == name then
		local content = meta:get_int("content")
		if (content+1000) <= 8000 then
			meta:set_int("content", content + 1000)
			itemstack = ItemStack("bucket:bucket_empty")
		end
	end
	update_tank(pos, meta)
	return itemstack
end

--[[
	The empty tank
]]
minetest.register_node("tanks:tank", {
	description="Tank",
	drawtype="allfaces",
	tiles={"tanks_window.png"},
	groups = {cracky=3, tank=1},
	paramtype="light",
	stack_max = 1,
	on_rightclick=on_rightclick,
	after_place_node=place_tank,
	on_dig = dig_tank,
	on_punch = punch_tank,
})

--[[
	Register a liquid for tank
]]
function tanks.register_tank(name, desc, bucket, liquid, bg)
	tanks.reg[name] = {}
	tanks.reg[name].liquid = liquid
	tanks.reg[name].bucket = bucket
	for i=1,8 do
		local side = "tanks_window.png^".."[lowpart:"..(12.5*i)..":"..bg.."^tanks_window.png"
		local top = "tanks_window.png"
		if i == 8 then
			top = bg.."^tanks_window.png"
		end	
		minetest.register_node(":tanks:tank_"..name.."_"..i, {
			description=desc,
			drawtype="nodebox",
			tiles={top, bg.."^tanks_window.png", side, side, side},
			groups = {cracky=3, tank=1},
			paramtype="light",
			nodebox = {
				type="regular",
			},
			stack_max = 1,
			on_rightclick=on_rightclick,
			after_place_node=place_tank,
			on_dig = dig_tank,
			on_punch = punch_tank,
		})
	end
end

tanks.register_tank("water", "Water tank", "bucket:bucket_water", "default:water_source", "tanks_water.png")
tanks.register_tank("river_water", "River water tank", "bucket:bucket_river_water", "default:river_water_source", "tanks_river_water.png")
tanks.register_tank("lava", "Lava tank", "bucket:bucket_lava", "default:lava_source", "tanks_lava.png")