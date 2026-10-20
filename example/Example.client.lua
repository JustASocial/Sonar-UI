local Sonar = require(game:GetService("ReplicatedStorage"):WaitForChild("Sonar"))

local window = Sonar.createWindow({
	Title = "Sonar UI",
	Subtitle = "Material 3 library",
	Icon = "sparkles",
	Theme = "Material",
	Mode = "dark",
	Accent = Color3.fromRGB(103, 80, 164),
	Layout = "sidebar",
	Size = UDim2.fromOffset(820, 560),
	MinSize = UDim2.fromOffset(520, 360),
	AutoSave = true,
	ConfigName = "sonar-demo",
	Locale = {
		default = "en",
		languages = {
			en = {
				WINDOW_TITLE = "Sonar UI",
				TAB_BASIC = "Basics",
				TAB_INPUTS = "Inputs",
				TAB_LAYOUT = "Layout",
				TAB_SPECIAL = "Sonar original",
				TAB_THEME = "Theme",
				GREETING = "Everything here is Material Design 3.",
			},
			ru = {
				WINDOW_TITLE = "Sonar UI",
				TAB_BASIC = "РћСЃРЅРѕРІС‹",
				TAB_INPUTS = "РџРѕР»СЏ РІРІРѕРґР°",
				TAB_LAYOUT = "Р Р°СЃРєР»Р°РґРєР°",
				TAB_SPECIAL = "Р¤РёСЂРјРµРЅРЅС‹Рµ СЌР»РµРјРµРЅС‚С‹",
				TAB_THEME = "РўРµРјР°",
				GREETING = "Р—РґРµСЃСЊ РІСЃС‘ РїРѕ Material Design 3.",
			},
		},
	},
})

window:show()

local basic = window:createTab({ Title = "loc:TAB_BASIC", Icon = "house" })
local inputs = window:createTab({ Title = "loc:TAB_INPUTS", Icon = "sliders-horizontal" })
local layout = window:createTab({ Title = "loc:TAB_LAYOUT", Icon = "layout-grid" })
local special = window:createTab({ Title = "loc:TAB_SPECIAL", Icon = "wand-2" })
local themeTab = window:createTab({ Title = "loc:TAB_THEME", Icon = "palette" })

local section = basic:createSection({ Title = "Buttons", Icon = "circle-dot" })

section:createButton({
	Title = "Filled button",
	Description = "Default Material 3 action",
	Icon = "zap",
	Callback = function()
		window:notify({ Title = "Button pressed", Content = "Callback fired", Icon = "check" })
	end,
})

section:createButton({
	Title = "Tonal button",
	Variant = "tonal",
	Icon = "heart",
	Callback = function()
		window:notify({ Title = "Tonal", Content = "Secondary container fill", Icon = "heart" })
	end,
})

section:createButton({
	Title = "Outlined button",
	Variant = "outlined",
	Icon = "download",
	Callback = function()
		window:notify({ Title = "Outlined", Content = "Bordered action", Icon = "download" })
	end,
})

section:createButton({
	Title = "Text button",
	Variant = "text",
	Icon = "external-link",
	Callback = function()
		window:popup({
			Title = "Material 3 dialog",
			Content = "Dialogs are modal surfaces with a scrim, a headline and actions.",
			Icon = "info",
			Buttons = {
				{ Title = "Cancel" },
				{ Title = "Confirm", Variant = "primary", Callback = function()
					window:notify({ Title = "Confirmed", Icon = "check" })
				end },
			},
		})
	end,
})

local toggles = basic:createSection({ Title = "Toggles", Icon = "circle-check" })

toggles:createToggle({
	Title = "Dark mode",
	Description = "Switches between light and dark schemes",
	Value = true,
	Flag = "darkMode",
	Callback = function(value)
		window:setTheme({ mode = value and "dark" or "light" })
	end,
})

toggles:createCheckbox({
	Title = "Checkbox",
	Description = "Standard selection control",
	Value = false,
	Flag = "checkbox",
	Callback = function(value)
		window:notify({ Title = "Checkbox", Content = tostring(value), Icon = "check" })
	end,
})

toggles:createRadio({
	Title = "Radio button",
	Variant = "Radio",
	Description = "Mutually exclusive choice",
	Flag = "radio",
	Callback = function(value)
		window:notify({ Title = "Radio", Content = tostring(value), Icon = "check" })
	end,
})

local statSection = basic:createSection({ Title = "Stats", Icon = "activity" })

statSection:createStat({
	Title = "Ping",
	Description = "Round trip to the server",
	Value = 42,
	Suffix = " ms",
	Change = 8,
	ChangeSuffix = "%",
})

statSection:createProgressBar({
	Title = "Download",
	Description = "Progress toward the latest build",
	Value = 64,
})

statSection:createProgressBar({
	Title = "Upload",
	Variant = "Circular",
	Value = 32,
})

local inputSection = inputs:createSection({ Title = "Text", Icon = "type" })

inputSection:createInput({
	Title = "Username",
	Description = "Plain text field",
	Placeholder = "Enter a name",
	Flag = "username",
	Callback = function(value)
		window:notify({ Title = "Username", Content = value })
	end,
})

inputSection:createInput({
	Title = "Amount",
	Description = "Numeric field, digits only",
	Placeholder = "0",
	Numeric = true,
	MaxLength = 8,
})

inputSection:createTextArea({
	Title = "Notes",
	Description = "Multi line field",
	Placeholder = "Write something",
})

inputSection:createDropdown({
	Title = "Quality",
	Description = "Single select menu",
	Options = { "Low", "Medium", "High", "Ultra" },
	Value = "Medium",
	Flag = "quality",
})

inputSection:createDropdown({
	Title = "Tags",
	Description = "Multi select menu",
	Options = { "PvP", "PvE", "Ranked", "Casual" },
	Multi = true,
})

inputSection:createKeybind({
	Title = "Toggle UI",
	Description = "Click and press a key",
	Flag = "toggleKey",
})

inputSection:createColorPicker({
	Title = "Accent",
	Description = "Full HSV picker with hex input",
	Flag = "accentColor",
})

local sliderSection = inputs:createSection({ Title = "Ranges", Icon = "sliders" })

sliderSection:createSlider({
	Title = "Volume",
	Description = "Continuous range",
	Min = 0,
	Max = 100,
	Step = 1,
	Value = 70,
	Suffix = "%",
	Flag = "volume",
	Callback = function(value)
		window:notify({ Title = "Volume", Content = tostring(value) .. "%", Duration = 1 })
	end,
})

sliderSection:createRating({
	Title = "Quality rating",
	Description = "Five point rating",
	Value = 4,
	Max = 5,
})

local layoutSection = layout:createSection({ Title = "Groups", Icon = "columns-3" })

local row = layoutSection:createGroup({ Direction = "row", Gap = 8 })
row:createButton({ Title = "Left", Variant = "tonal" })
row:createButton({ Title = "Middle", Variant = "tonal" })
row:createButton({ Title = "Right", Variant = "tonal" })

local column = layoutSection:createGroup({ Direction = "column", Gap = 8 })
column:createButton({ Title = "Top", Variant = "outlined" })
column:createButton({ Title = "Bottom", Variant = "outlined" })

layoutSection:createDivider({ Text = "OR" })
layoutSection:createSpace({ Size = 12 })
layoutSection:createParagraph({
	Title = "Section in a section",
	Description = "Sections are collapsible groups with a header, a chevron and a bordered body.",
	Buttons = {
		{ Title = "Primary action", Variant = "filled", Callback = function()
			window:notify({ Title = "Paragraph button", Icon = "check" })
		end },
	},
})

layoutSection:createBadge({ Text = "New", Variant = "primary", Icon = "sparkles" })
layoutSection:createBadge({ Text = "Stable", Variant = "success" })

local codeSection = layout:createSection({ Title = "Code and logs", Icon = "terminal" })

codeSection:createCode({
	Title = "example.lua",
	Code = "local window = Sonar.createWindow({\n\tTitle = \"Sonar UI\",\n\tTheme = \"Material\",\n})\n\nwindow:show()",
})

local console = codeSection:createConsole({
	Title = "Console",
	Height = 150,
	MaxLines = 40,
})
console:write("Sonar console ready", "success")
console:write("Type is loaded", "info")

local specialSection = special:createSection({ Title = "Sonar original", Icon = "rocket" })

specialSection:createStepper({
	Title = "Onboarding",
	Description = "Three steps, click to move between them",
	Steps = {
		{ Title = "Install", Icon = "download" },
		{ Title = "Configure", Icon = "settings" },
		{ Title = "Ship", Icon = "rocket" },
	},
	Value = 1,
	Callback = function(step)
		window:notify({ Title = "Step " .. step, Icon = "chevron-right" })
	end,
})

specialSection:createChipGroup({
	Title = "Chips",
	Description = "Material 3 chip set, wraps on new lines",
	Variant = "filter",
	Options = {
		{ Title = "Windows", Icon = "monitor" },
		{ Title = "macOS", Icon = "sun" },
		{ Title = "Linux", Icon = "terminal" },
		{ Title = "Android", Icon = "smartphone" },
		{ Title = "iOS", Icon = "tablet" },
	},
	Multi = true,
})

specialSection:createImageUploader({
	Title = "Banner",
	Description = "Paste a link, drop a file or paste from the clipboard",
	Placeholder = "Paste an image link or drop a file here",
	OnSelect = function(source)
		window:notify({ Title = "Image ready", Content = source, Icon = "image" })
	end,
})

specialSection:createImage({
	Image = "rbxassetid://13160411435",
	AspectRatio = "16:9",
	Width = 320,
	Caption = "Preview with rounded corners",
})

local themeSection = themeTab:createSection({ Title = "Material You", Icon = "palette" })

themeSection:createParagraph({
	Title = "Dynamic color",
	Description = "Every scheme is generated from a seed colour with perceptual (Oklab) tonal palettes, exactly like Material You.",
})

local seeds = {
	{ Name = "Material", Color = Color3.fromRGB(103, 80, 164) },
	{ Name = "Blue", Color = Color3.fromRGB(21, 101, 192) },
	{ Name = "Green", Color = Color3.fromRGB(46, 125, 50) },
	{ Name = "Red", Color = Color3.fromRGB(179, 38, 30) },
	{ Name = "Orange", Color = Color3.fromRGB(232, 113, 10) },
	{ Name = "Teal", Color = Color3.fromRGB(0, 106, 106) },
	{ Name = "Pink", Color = Color3.fromRGB(179, 38, 126) },
}

for _, seed in ipairs(seeds) do
	themeSection:createButton({
		Title = seed.Name,
		Variant = "tonal",
		Callback = function()
			window:setAccent(seed.Color)
		end,
	})
end

themeSection:createDivider({ Text = "Language" })
themeSection:createButton({
	Title = "English",
	Variant = "outlined",
	Callback = function()
		window:setLanguage("en")
	end,
})
themeSection:createButton({
	Title = "Р СѓСЃСЃРєРёР№",
	Variant = "outlined",
	Callback = function()
		window:setLanguage("ru")
	end,
})

themeSection:createDivider({ Text = "Config" })
themeSection:createButton({
	Title = "Save config",
	Variant = "outlined",
	Icon = "save",
	Callback = function()
		window:saveConfig()
		window:notify({ Title = "Config saved", Icon = "save" })
	end,
})
themeSection:createButton({
	Title = "Load config",
	Variant = "outlined",
	Icon = "folder-open",
	Callback = function()
		window:loadConfig()
		window:notify({ Title = "Config loaded", Icon = "folder-open" })
	end,
})
themeSection:createButton({
	Title = "Switch layout",
	Variant = "outlined",
	Icon = "panel-left",
	Callback = function()
		window:setLayout(window.layout == "sidebar" and "top" or "sidebar")
	end,
})
