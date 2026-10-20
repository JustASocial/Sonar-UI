local Lucide = require(script.Parent.Lucide)

local Icons = {}

Icons.packs = {
	lucide = Lucide,
}

Icons.defaultPack = "lucide"

local function splitName(name)
	local separator = name:find(":", 1, true)
	if separator then
		return name:sub(1, separator - 1), name:sub(separator + 1)
	end
	return nil, name
end

function Icons.register(packName, data)
	Icons.packs[packName] = data
end

function Icons.setDefaultPack(packName)
	Icons.defaultPack = packName
end

function Icons.exists(name)
	if type(name) ~= "string" then
		return false
	end
	if name:sub(1, 10) == "rbxassetid:" or name:sub(1, 7) == "rbxasset:" then
		return true
	end
	if name:sub(1, 4) == "http" then
		return true
	end
	local pack, key = splitName(name)
	pack = pack or Icons.defaultPack
	local data = Icons.packs[pack]
	return data ~= nil and data[key] ~= nil
end

function Icons.image(name)
	if type(name) == "number" then
		return "rbxassetid://" .. tostring(name)
	end
	if type(name) ~= "string" then
		return nil
	end
	if name:sub(1, 10) == "rbxassetid:" or name:sub(1, 7) == "rbxasset:" or name:sub(1, 4) == "http" then
		return name
	end
	local pack, key = splitName(name)
	pack = pack or Icons.defaultPack
	local data = Icons.packs[pack]
	if not data then
		return nil
	end
	return data[key]
end

function Icons.names()
	local names = {}
	for key in pairs(Lucide) do
		table.insert(names, key)
	end
	table.sort(names)
	return names
end

function Icons.label(parent, name, size, color)
	local image = Icons.image(name)
	local label = Instance.new("ImageLabel")
	label.Name = "Icon"
	label.BackgroundTransparency = 1
	label.Size = typeof(size) == "number" and UDim2.fromOffset(size, size) or (size or UDim2.fromOffset(20, 20))
	label.Image = image or ""
	label.ImageColor3 = color or Color3.fromRGB(255, 255, 255)
	label.ScaleType = Enum.ScaleType.Fit
	label.Parent = parent
	return label
end

return Icons
