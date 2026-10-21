local Tokens = {}

Tokens.Shape = {
	none = 0,
	extraSmall = 4,
	small = 8,
	medium = 12,
	large = 16,
	largeIncreased = 20,
	extraLarge = 28,
	extraLargeIncreased = 32,
	extraExtraLarge = 48,
	full = 999,
}

Tokens.Elevation = {
	level0 = { surface = "surface", shadow = 0 },
	level1 = { surface = "surfaceContainerLow", shadow = 0.25 },
	level2 = { surface = "surfaceContainer", shadow = 0.3 },
	level3 = { surface = "surfaceContainerHigh", shadow = 0.35 },
	level4 = { surface = "surfaceContainerHighest", shadow = 0.38 },
	level5 = { surface = "surfaceContainerHighest", shadow = 0.42 },
}

Tokens.Motion = {
	emphasized = { time = 0.55, style = Enum.EasingStyle.Quint, direction = Enum.EasingDirection.Out },
	emphasizedDecelerate = { time = 0.45, style = Enum.EasingStyle.Quint, direction = Enum.EasingDirection.Out },
	emphasizedAccelerate = { time = 0.25, style = Enum.EasingStyle.Quart, direction = Enum.EasingDirection.Out },
	standard = { time = 0.35, style = Enum.EasingStyle.Quart, direction = Enum.EasingDirection.Out },
	standardDecelerate = { time = 0.3, style = Enum.EasingStyle.Quad, direction = Enum.EasingDirection.Out },
	standardAccelerate = { time = 0.22, style = Enum.EasingStyle.Quad, direction = Enum.EasingDirection.Out },
	short = { time = 0.2, style = Enum.EasingStyle.Quad, direction = Enum.EasingDirection.Out },
	short4 = { time = 0.11, style = Enum.EasingStyle.Quad, direction = Enum.EasingDirection.Out },
	slow = { time = 0.8, style = Enum.EasingStyle.Quint, direction = Enum.EasingDirection.Out },
}

Tokens.Type = {
	displayLarge = { size = 52, lineHeight = 60, tracking = -0.25, weight = "regular" },
	displayMedium = { size = 42, lineHeight = 52, tracking = 0, weight = "regular" },
	displaySmall = { size = 34, lineHeight = 44, tracking = 0, weight = "regular" },
	headlineLarge = { size = 30, lineHeight = 38, tracking = 0, weight = "regular" },
	headlineMedium = { size = 26, lineHeight = 34, tracking = 0, weight = "regular" },
	headlineSmall = { size = 22, lineHeight = 30, tracking = 0, weight = "regular" },
	titleLarge = { size = 20, lineHeight = 26, tracking = 0, weight = "bold" },
	titleMedium = { size = 16, lineHeight = 24, tracking = 0.15, weight = "bold" },
	titleSmall = { size = 14, lineHeight = 20, tracking = 0.1, weight = "bold" },
	bodyLarge = { size = 16, lineHeight = 24, tracking = 0.5, weight = "regular" },
	bodyMedium = { size = 14, lineHeight = 20, tracking = 0.25, weight = "regular" },
	bodySmall = { size = 12, lineHeight = 16, tracking = 0.4, weight = "regular" },
	labelLarge = { size = 14, lineHeight = 20, tracking = 0.1, weight = "bold" },
	labelMedium = { size = 12, lineHeight = 16, tracking = 0.5, weight = "bold" },
	labelSmall = { size = 11, lineHeight = 16, tracking = 0.5, weight = "bold" },
}

Tokens.Fonts = {
	regular = Enum.Font.Gotham,
	medium = Enum.Font.GothamMedium,
	bold = Enum.Font.GothamBold,
	black = Enum.Font.GothamBlack,
	mono = Enum.Font.RobotoMono,
}

Tokens.Spacing = {
	xxs = 2,
	xs = 4,
	sm = 8,
	md = 12,
	lg = 16,
	xl = 24,
	xxl = 32,
	xxxl = 48,
}

Tokens.Density = {
	scale = 1,
	radiusScale = 1,
}

function Tokens.shapeRadius(name)
	local base = Tokens.Shape[name] or Tokens.Shape.medium
	return UDim.new(0, math.round(base * Tokens.Density.radiusScale))
end

function Tokens.typeScale(name)
	return Tokens.Type[name] or Tokens.Type.bodyMedium
end

function Tokens.motion(name)
	return Tokens.Motion[name] or Tokens.Motion.standard
end

return Tokens
