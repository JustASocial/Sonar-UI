local Palette = {}

local function clamp(value, min, max)
	if value < min then
		return min
	elseif value > max then
		return max
	end
	return value
end

local function srgbToLinear(channel)
	if channel <= 0.04045 then
		return channel / 12.92
	end
	return ((channel + 0.055) / 1.055) ^ 2.4
end

local function linearToSrgb(channel)
	if channel <= 0.0031308 then
		return channel * 12.92
	end
	return 1.055 * (channel ^ (1 / 2.4)) - 0.055
end

local function cbrt(value)
	if value < 0 then
		return -((-value) ^ (1 / 3))
	end
	return value ^ (1 / 3)
end

function Palette.rgbToOklab(color)
	local red = srgbToLinear(color.R)
	local green = srgbToLinear(color.G)
	local blue = srgbToLinear(color.B)

	local long = 0.4122214708 * red + 0.5363325363 * green + 0.0514459929 * blue
	local medium = 0.2119034982 * red + 0.6806995451 * green + 0.1073969566 * blue
	local short = 0.0883024619 * red + 0.2817188376 * green + 0.6299787005 * blue

	local longRoot = cbrt(long)
	local mediumRoot = cbrt(medium)
	local shortRoot = cbrt(short)

	local lightness = 0.2104542553 * longRoot + 0.793617785 * mediumRoot - 0.0040720468 * shortRoot
	local a = 1.9779984951 * longRoot - 2.428592205 * mediumRoot + 0.4505937099 * shortRoot
	local b = 0.0259040371 * longRoot + 0.7827717662 * mediumRoot - 0.808675766 * shortRoot

	return lightness, a, b
end

function Palette.oklabToLinear(lightness, a, b)
	local longRoot = lightness + 0.3963377774 * a + 0.2158037573 * b
	local mediumRoot = lightness - 0.1055613458 * a - 0.0638541728 * b
	local shortRoot = lightness - 0.0894841775 * a - 1.291485548 * b

	local long = longRoot * longRoot * longRoot
	local medium = mediumRoot * mediumRoot * mediumRoot
	local short = shortRoot * shortRoot * shortRoot

	local red = 4.0767416621 * long - 3.3077115913 * medium + 0.2309699292 * short
	local green = -1.2684380046 * long + 2.6097574011 * medium - 0.3413193965 * short
	local blue = -0.0041960863 * long - 0.7034186147 * medium + 1.707614701 * short

	return red, green, blue
end

local function inGamut(red, green, blue)
	return red >= -0.0001 and red <= 1.0001 and green >= -0.0001 and green <= 1.0001 and blue >= -0.0001 and blue <= 1.0001
end

function Palette.oklabToColor(lightness, a, b)
	local low = 0
	local high = 1
	local red, green, blue

	for _ = 1, 16 do
		local mid = (low + high) / 2
		red, green, blue = Palette.oklabToLinear(lightness, a * mid, b * mid)
		if inGamut(red, green, blue) then
			low = mid
		else
			high = mid
		end
	end

	red, green, blue = Palette.oklabToLinear(lightness, a * low, b * low)

	return Color3.new(clamp(linearToSrgb(red), 0, 1), clamp(linearToSrgb(green), 0, 1), clamp(linearToSrgb(blue), 0, 1))
end

local BOOST = {
	primary = 1,
	secondary = 0.42,
	tertiary = 0.58,
	neutral = 0.08,
	neutralVariant = 0.14,
	error = 1,
}

local PALETTE_CACHE = {}

local function buildPalettes(seed)
	local lightness, a, b = Palette.rgbToOklab(seed)
	local chroma = math.sqrt(a * a + b * b)

	local palettes = {}
	for name, boost in BOOST do
		palettes[name] = { a = a * boost, b = b * boost, chroma = chroma * boost }
	end
	palettes.primary.lightness = lightness
	return palettes
end

function Palette.palettes(seed)
	local key = string.format("%.4f|%.4f|%.4f", seed.R, seed.G, seed.B)
	local cached = PALETTE_CACHE[key]
	if cached then
		return cached
	end
	local built = buildPalettes(seed)
	PALETTE_CACHE[key] = built
	return built
end

function Palette.toneColor(palettes, family, tone)
	tone = clamp(math.round(tone), 0, 100)
	local palette = palettes[family]
	local key = family .. ":" .. tone
	local cached = PALETTE_CACHE[key]
	if cached then
		return cached
	end
	local color = Palette.oklabToColor(tone / 100, palette.a, palette.b)
	PALETTE_CACHE[key] = color
	return color
end

function Palette.errorPalettes()
	local cached = PALETTE_CACHE["__error"]
	if cached then
		return cached
	end
	local built = buildPalettes(Color3.fromRGB(179, 38, 30))
	built.primary = built.error
	PALETTE_CACHE["__error"] = built
	return built
end

function Palette.scheme(seed, dark)
	local palettes = Palette.palettes(seed)
	local errors = Palette.errorPalettes()
	local function tone(family, value)
		return Palette.toneColor(palettes, family, value)
	end
	local function errorTone(value)
		return Palette.toneColor(errors, "error", value)
	end

	local scheme

	if dark then
		scheme = {
			mode = "dark",
			primary = tone("primary", 80),
			onPrimary = tone("primary", 20),
			primaryContainer = tone("primary", 30),
			onPrimaryContainer = tone("primary", 90),
			secondary = tone("secondary", 80),
			onSecondary = tone("secondary", 20),
			secondaryContainer = tone("secondary", 30),
			onSecondaryContainer = tone("secondary", 90),
			tertiary = tone("tertiary", 80),
			onTertiary = tone("tertiary", 20),
			tertiaryContainer = tone("tertiary", 30),
			onTertiaryContainer = tone("tertiary", 90),
			error = errorTone(80),
			onError = errorTone(20),
			errorContainer = errorTone(30),
			onErrorContainer = errorTone(90),
			background = tone("neutral", 6),
			onBackground = tone("neutral", 90),
			surface = tone("neutral", 6),
			onSurface = tone("neutral", 90),
			surfaceVariant = tone("neutralVariant", 30),
			onSurfaceVariant = tone("neutralVariant", 80),
			outline = tone("neutralVariant", 60),
			outlineVariant = tone("neutralVariant", 30),
			surfaceDim = tone("neutral", 6),
			surfaceBright = tone("neutral", 24),
			surfaceContainerLowest = tone("neutral", 4),
			surfaceContainerLow = tone("neutral", 10),
			surfaceContainer = tone("neutral", 12),
			surfaceContainerHigh = tone("neutral", 17),
			surfaceContainerHighest = tone("neutral", 22),
			inverseSurface = tone("neutral", 90),
			inverseOnSurface = tone("neutral", 20),
			inversePrimary = tone("primary", 40),
			shadow = Color3.new(0, 0, 0),
			scrim = Color3.new(0, 0, 0),
		}
	else
		scheme = {
			mode = "light",
			primary = tone("primary", 40),
			onPrimary = tone("primary", 100),
			primaryContainer = tone("primary", 90),
			onPrimaryContainer = tone("primary", 10),
			secondary = tone("secondary", 40),
			onSecondary = tone("secondary", 100),
			secondaryContainer = tone("secondary", 90),
			onSecondaryContainer = tone("secondary", 10),
			tertiary = tone("tertiary", 40),
			onTertiary = tone("tertiary", 100),
			tertiaryContainer = tone("tertiary", 90),
			onTertiaryContainer = tone("tertiary", 10),
			error = errorTone(40),
			onError = errorTone(100),
			errorContainer = errorTone(90),
			onErrorContainer = errorTone(10),
			background = tone("neutral", 98),
			onBackground = tone("neutral", 10),
			surface = tone("neutral", 98),
			onSurface = tone("neutral", 10),
			surfaceVariant = tone("neutralVariant", 90),
			onSurfaceVariant = tone("neutralVariant", 30),
			outline = tone("neutralVariant", 50),
			outlineVariant = tone("neutralVariant", 80),
			surfaceDim = tone("neutral", 87),
			surfaceBright = tone("neutral", 98),
			surfaceContainerLowest = tone("neutral", 100),
			surfaceContainerLow = tone("neutral", 96),
			surfaceContainer = tone("neutral", 94),
			surfaceContainerHigh = tone("neutral", 92),
			surfaceContainerHighest = tone("neutral", 90),
			inverseSurface = tone("neutral", 20),
			inverseOnSurface = tone("neutral", 95),
			inversePrimary = tone("primary", 80),
			shadow = Color3.new(0, 0, 0),
			scrim = Color3.new(0, 0, 0),
		}
	end

	scheme.stateHover = 0.08
	scheme.stateFocus = 0.1
	scheme.statePressed = 0.1
	scheme.stateDragged = 0.16
	scheme.stateDisabled = 0.38
	scheme.stateDisabledContent = 0.38

	return scheme
end

function Palette.seedFromHex(hex)
	hex = hex:gsub("#", "")
	if #hex == 3 then
		hex = hex:sub(1, 1):rep(2) .. hex:sub(2, 2):rep(2) .. hex:sub(3, 3):rep(2)
	end
	return Color3.fromRGB(tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16))
end

function Palette.toHex(color)
	return string.format("#%02X%02X%02X", math.round(color.R * 255), math.round(color.G * 255), math.round(color.B * 255))
end

return Palette
