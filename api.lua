local callbacks = {}

-- Make it avilabel to other mods
tanks.callbacks = callbacks

callbacks.on_update = {}
callbacks.num_update = 0

callbacks.on_place  = {}
callbacks.num_place = 0

callbacks.on_dig   = {}
callbacks.num_dig = 0

callbacks.on_punch   = {}
callbacks.num_punch = 0

callbacks.on_rightclick   = {}
callbacks.num_rightclick = 0

function tanks.on_update(pos, meta)
	for _, f in pairs(callbacks.on_update) do
		if f(pos, meta) then
			return true
		end
	end
end

function tanks.on_place(pos, placer, itemstack, pt)
	for _, f in pairs(callbacks.on_place) do
		if f(pos, placer, itemstack, pt) then
			return true
		end
	end
end

function tanks.on_dig(pos, node, player)
	for _, f in pairs(callbacks.on_dig) do
		if f(pos, node, player) then
			return true
		end
	end
end

function tanks.on_punch(pos, node, player, item, pt)
	for _,f in pairs(callbacks.on_punch) do
		local ret = f(pos, node, player, item, pt)
		if ret then
			return ret
		end
	end
end

function tanks.on_rightclick(pos, node, player, item, pt)
	for _,f in pairs(callbacks.on_rightclick) do
		local ret = f(pos, node, player, item, pt)
		if ret then
			return ret
		end
	end
end

function tanks.register_on_update(f)
	callbacks.on_update[callbacks.num_update] = f
	callbacks.num_update = callbacks.num_update + 1
end

function tanks.register_on_place(f)
	callbacks.on_place[callbacks.num_place] = f
	callbacks.num_place = callbacks.num_place + 1
end

function tanks.register_on_dig(f)
	callbacks.on_dig[callbacks.num_dig] = f
	callbacks.num_dig = callbacks.num_dig + 1
end

function tanks.register_on_punch(f)
	callbacks.on_punch[callbacks.num_punch] = f
	callbacks.num_punch = callbacks.num_punch + 1
end

function tanks.register_on_rightclick(f)
	callbacks.on_rightclick[callbacks.num_rightclick] = f
	callbacks.num_rightclick = callbacks.num_rightclick + 1
end
