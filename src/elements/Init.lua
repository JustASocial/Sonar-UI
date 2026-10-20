local Elements = {}

local MODULES = {
	Badge = "Badge",
	Button = "Button",
	Checkbox = "Checkbox",
	ChipGroup = "ChipGroup",
	Code = "Code",
	ColorPicker = "ColorPicker",
	Console = "Console",
	Divider = "Divider",
	Dropdown = "Dropdown",
	Image = "Image",
	ImageUploader = "ImageUploader",
	Input = "Input",
	Keybind = "Keybind",
	Paragraph = "Paragraph",
	ProgressBar = "ProgressBar",
	Radio = "Radio",
	Rating = "Rating",
	Slider = "Slider",
	Space = "Space",
	Stat = "Stat",
	Stepper = "Stepper",
	TextArea = "TextArea",
	Toggle = "Toggle",
}

local cache = {}

function Elements.get(name)
	if cache[name] then
		return cache[name]
	end
	local file = MODULES[name]
	if not file then
		return nil
	end
	local module = require(script[file])
	cache[name] = module
	return module
end

function Elements.names()
	local names = {}
	for name in pairs(MODULES) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

return Elements
