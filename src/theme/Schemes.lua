local Palette = require(script.Parent.Palette)

local Schemes = {}

local SEEDS = {
	Material = Color3.fromRGB(103, 80, 164),
	Blue = Color3.fromRGB(21, 101, 192),
	Green = Color3.fromRGB(46, 125, 50),
	Red = Color3.fromRGB(179, 38, 30),
	Orange = Color3.fromRGB(232, 113, 10),
	Teal = Color3.fromRGB(0, 106, 106),
	Pink = Color3.fromRGB(179, 38, 126),
	Monochrome = Color3.fromRGB(120, 120, 124),
	Mint = Color3.fromRGB(0, 137, 123),
	Crimson = Color3.fromRGB(191, 45, 55),
	Violet = Color3.fromRGB(124, 58, 191),
}

Schemes.seeds = SEEDS

local function cloneDeep(source)
	local result = {}
	for key, value in pairs(source) do
		if type(value) == "table" then
			result[key] = cloneDeep(value)
		else
			result[key] = value
		end
	end
	return result
end

function Schemes.resolve(name, mode, seed)
	if seed == nil then
		local found = SEEDS[name]
		if found == nil then
			for key, value in pairs(SEEDS) do
				if key:lower() == tostring(name):lower() then
					found = value
					break
				end
			end
		end
		seed = found or SEEDS.Material
	end

	mode = mode or "dark"
	local colors = Palette.scheme(seed, mode == "dark")

	return {
		name = name,
		mode = mode,
		seed = seed,
		colors = colors,
	}
end

function Schemes.register(name, spec)
	SEEDS[name] = spec.seed
end

function Schemes.list()
	local names = {}
	for key in pairs(SEEDS) do
		table.insert(names, key)
	end
	table.sort(names)
	return names
end

Schemes.cloneDeep = cloneDeep

return Schemes
