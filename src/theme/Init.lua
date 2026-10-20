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

function Theme.build(spec)
	spec = spec or {}
	local scheme = Schemes.resolve(spec.name or "Material", spec.mode or "dark", spec.seed)
	local colors = scheme.colors

	if spec.colors then
		for role, value in pairs(spec.colors) do
			if type(value) == "string" then
				colors[role] = Palette.seedFromHex(value)
			elseif type(value) == "Color3" then
				colors[role] = value
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
				shape[role] = UDim.new(0, value)
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

	local elevation = {}
	for level, entry in pairs(Tokens.Elevation) do
		elevation[level] = {
			color = colors[entry.surface] or colors.surface,
			shadowTransparency = entry.shadow,
		}
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
		state = {
			hover = colors.stateHover or 0.08,
			focus = colors.stateFocus or 0.1,
			pressed = colors.statePressed or 0.1,
			dragged = colors.stateDragged or 0.16,
			disabled = colors.stateDisabled or 0.38,
			disabledContent = colors.stateDisabledContent or 0.38,
		},
	}
end

function Theme.schemes()
	return Schemes.list()
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

return Theme
