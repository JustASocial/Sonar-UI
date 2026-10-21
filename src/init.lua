local Window = require(script.core.Window)
local Theme = require(script.theme.Init)
local Schemes = require(script.theme.Schemes)
local Palette = require(script.theme.Palette)
local Tokens = require(script.theme.Tokens)
local Icons = require(script.icons.Init)
local Variables = require(script.core.Variables)

local Sonar = {}

Sonar.version = "1.0.0"
Sonar.name = "Sonar UI"

Sonar.Theme = Theme
Sonar.Tokens = Tokens
Sonar.Schemes = Schemes
Sonar.Palette = Palette
Sonar.Icons = Icons

local activeWindows = {}

function Sonar.createWindow(props)
	local window = Window.new(props or {})
	table.insert(activeWindows, window)
	return window
end

function Sonar.buildTheme(spec)
	return Theme.build(spec or {})
end

function Sonar.palette(seed, mode)
	return Theme.palette(seed, mode)
end

function Sonar.schemes()
	return Schemes.list()
end

function Sonar.materials()
	return Palette
end

function Sonar.setIconsPack(pack)
	Icons.setDefaultPack(pack)
end

function Sonar.icons()
	return Icons.names()
end

function Sonar.windows()
	local list = {}
	for _, window in ipairs(activeWindows) do
		if not window.unloaded then
			table.insert(list, window)
		end
	end
	return list
end

function Sonar.destroyAll()
	for _, window in ipairs(activeWindows) do
		if not window.unloaded then
			window:unload()
		end
	end
	activeWindows = {}
end

Sonar.Variables = Variables

return Sonar
