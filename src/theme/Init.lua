local Tokens = require(script.Parent.Tokens)
local Schemes = require(script.Parent.Schemes)
local Palette = require(script.Parent.Palette)

local Theme = {}

local SHAPE_ROLES = {
	window = "extraLarge",
	sheet = "largeIncreased",
	dialog = "extraLarge",
	card = "large",
	element = "medium",
	menu = "small",
	field = "small",
	chip = "small",
	button = "full",
	toggle = "full",
	badge = "full",
	nav = "full",
	progress = "full",
	tab = "full",
	snackbar = "extraSmall",
}

local function copy(source)
	local result = {}
	for key, value in pairs(source) do
		if type(value) == "table" and getmetatable(value) == nil then
			result[key] = copy(value)
		else
			result[key] = value
		end
	end
	return result
end

local function resolveColor(value)
	if type(value) == "string" then
		return Palette.seedFromHex(value)
	end
	return value
end

function Theme.build(spec)
	spec = spec or {}

	local scheme = Schemes.resolve(spec.name or "Material", spec.mode or "dark", spec.seed)
	local colors = copy(scheme.colors)

	if spec.colors then
		for role, value in pairs(spec.colors) do
			local resolved = resolveColor(value)
			if resolved ~= nil then
				colors[role] = resolved
			end
		end
	end

	local shape = {}
	for role, token in pairs(SHAPE_ROLES) do
		shape[role] = Tokens.shapeRadius(token)
	end
	if spec.shape then
		for role, value in pairs(spec.shape) do
			if type(value) == "number" then
				shape[role] = UDim.new(0, math.round(value * (Tokens.Density.radiusScale or 1)))
			elseif type(value) == "UDim" then
				shape[role] = value
			end
		end
	end

	local fonts = {}
	for key, value in pairs(Tokens.Fonts) do
		fonts[key] = value
	end
	if spec.fonts then
		for key, value in pairs(spec.fonts) do
			fonts[key] = value
		end
	end

	local typeScale = {}
	for key, value in pairs(Tokens.Type) do
		typeScale[key] = {
			size = value.size,
			lineHeight = value.lineHeight,
			tracking = value.tracking,
			weight = value.weight,
			font = fonts[value.weight] or fonts.regular,
		}
	end
	if spec.type then
		for key, value in pairs(spec.type) do
			local current = typeScale[key] or {
				size = 14,
				lineHeight = 20,
				tracking = 0,
				weight = "regular",
			}
			if type(value) == "number" then
				current.size = value
			elseif type(value) == "table" then
				current.size = value.size or current.size
				current.lineHeight = value.lineHeight or current.lineHeight
				current.tracking = value.tracking or current.tracking
				current.weight = value.weight or current.weight
			end
			current.font = fonts[current.weight] or fonts.regular
			typeScale[key] = current
		end
	end

	local motion = {}
	for key, value in pairs(Tokens.Motion) do
		motion[key] = {
			time = value.time,
			style = value.style,
			direction = value.direction,
		}
	end
	if spec.motion then
		for key, value in pairs(spec.motion) do
			if type(value) == "number" then
				motion[key] = { time = value, style = motion.standard.style, direction = motion.standard.direction }
			elseif type(value) == "table" then
				motion[key] = {
					time = value.time or motion.standard.time,
					style = value.style or motion.standard.style,
					direction = value.direction or motion.standard.direction,
				}
			end
		end
	end

	local state = {
		hover = colors.stateHover or 0.08,
		focus = colors.stateFocus or 0.1,
		pressed = colors.statePressed or 0.1,
		dragged = colors.stateDragged or 0.16,
		disabled = colors.stateDisabled or 0.38,
		disabledContent = colors.stateDisabledContent or 0.38,
	}
	if spec.state then
		for key, value in pairs(spec.state) do
			if type(value) == "number" then
				state[key] = value
			end
		end
	end

	local elevation = {}
	for level, entry in pairs(Tokens.Elevation) do
		elevation[level] = {
			color = colors[entry.surface] or colors.surface,
			shadowTransparency = entry.shadow,
		}
	end
	if spec.elevation then
		for level, value in pairs(spec.elevation) do
			if type(value) == "number" then
				elevation[level] = {
					color = colors.surface,
					shadowTransparency = value,
				}
			elseif type(value) == "table" then
				local current = elevation[level] or { color = colors.surface, shadowTransparency = 0 }
				current.shadowTransparency = value.shadow or current.shadowTransparency
				current.color = resolveColor(value.surface) or current.color
				elevation[level] = current
			end
		end
	end

	return {
		name = scheme.name,
		mode = scheme.mode,
		seed = scheme.seed,
		colors = colors,
		shape = shape,
		motion = motion,
		type = typeScale,
		fonts = fonts,
		spacing = Tokens.Spacing,
		elevation = elevation,
		state = state,
	}
end

function Theme.schemes()
	return Schemes.list()
end

function Theme.palette(seed, mode)
	if type(seed) == "string" then
		seed = Palette.seedFromHex(seed)
	end
	return Palette.scheme(seed or Color3.fromRGB(103, 80, 164), mode == "light")
end

function Theme.contrast(color)
	local luminance = 0.299 * color.R + 0.587 * color.G + 0.114 * color.B
	if luminance > 0.55 then
		return Color3.fromRGB(20, 20, 20)
	end
	return Color3.fromRGB(255, 255, 255)
end

function Theme.withAlpha(color, alpha)
	return Color3.new(color.R, color.G, color.B), alpha
end

Theme.copy = copy

return Theme
