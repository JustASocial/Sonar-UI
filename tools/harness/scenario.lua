local Sonar = __require("init")

local window = Sonar.createWindow({
	Title = "Harness",
	Subtitle = "smoke test",
	Icon = "sparkles",
	Theme = "Material",
	Mode = "dark",
	Accent = Color3.fromRGB(103, 80, 164),
	Layout = "sidebar",
	Size = UDim2.fromOffset(820, 560),
	AutoSave = false,
	Locale = {
		default = "en",
		languages = {
			en = { TAB = "Basics" },
			ru = { TAB = "Р С›РЎРѓР Р…Р С•Р Р†РЎвЂ№" },
		},
	},
})

window:show()

local tab = window:createTab({ Title = "loc:TAB", Icon = "house" })
local section = tab:createSection({ Title = "Basics", Icon = "circle-dot" })

local button = section:createButton({
	Title = "Press me",
	Description = "A filled button",
	Icon = "zap",
	Callback = function()
		print("button callback fired")
	end,
})

local toggle = section:createToggle({
	Title = "Toggle",
	Description = "Switch",
	Value = false,
	Flag = "toggleFlag",
	Callback = function(value)
		print("toggle -> " .. tostring(value))
	end,
})

local checkbox = section:createCheckbox({ Title = "Checkbox", Value = false, Flag = "checkboxFlag" })
local radio = section:createRadio({ Title = "Radio", Value = false, Flag = "radioFlag" })
local slider = section:createSlider({ Title = "Volume", Min = 0, Max = 100, Step = 5, Value = 50, Flag = "sliderFlag" })
local rating = section:createRating({ Title = "Rating", Value = 3, Max = 5 })
local badge = section:createBadge({ Text = "New", Variant = "primary" })
local divider = section:createDivider({ Text = "OR" })
local space = section:createSpace({ Size = 10 })
local input = section:createInput({ Title = "Name", Placeholder = "Type here", Flag = "nameFlag" })
local area = section:createTextArea({ Title = "Notes", Placeholder = "Write" })
local dropdown = section:createDropdown({ Title = "Quality", Options = { "Low", "High" }, Value = "Low", Flag = "qualityFlag" })
local multi = section:createDropdown({ Title = "Tags", Options = { "A", "B" }, Multi = true })
local keybind = section:createKeybind({ Title = "Bind", Flag = "keyFlag" })
local color = section:createColorPicker({ Title = "Accent", Color = Color3.fromRGB(255, 0, 0), Flag = "colorFlag" })
local paragraph = section:createParagraph({ Title = "Paragraph", Description = "Body", Buttons = { { Title = "OK", Variant = "filled" } } })
local code = section:createCode({ Title = "a.lua", Code = "print('hi')" })
local console = section:createConsole({ Title = "Log", Height = 120 })
local image = section:createImage({ Image = "rbxassetid://1", Width = 200 })
local uploader = section:createImageUploader({ Title = "Banner" })
local chips = section:createChipGroup({ Title = "Chips", Options = { "One", "Two", "Three" }, Multi = true })
local stepper = section:createStepper({ Title = "Steps", Steps = { { Title = "A" }, { Title = "B" } }, Value = 1 })
local group = section:createGroup({ Direction = "row" })
group:createButton({ Title = "L", Variant = "tonal" })

print("--- interactions ---")

__fire(button.main, "MouseEnter")
__fire(button.main, "MouseButton1Click")
__fire(button.main, "MouseLeave")

__fire(toggle.switch, "MouseEnter")
__fire(toggle.switch, "MouseButton1Click")
print("toggle after click:", toggle.value)
__fire(toggle.switch, "MouseButton1Click")
print("toggle after second click:", toggle.value)

__fire(checkbox.box, "MouseButton1Click")
print("checkbox:", checkbox.value)
__fire(radio.box, "MouseButton1Click")
print("radio:", radio.value)

__fire(slider.trackArea, "InputBegan", { UserInputType = Enum.UserInputType.MouseButton1, Position = Vector2.new(200, 0) })
__fire(slider.trackArea, "InputEnded", { UserInputType = Enum.UserInputType.MouseButton1 })
print("slider after drag:", slider.value)

__fire(rating.stars[5].star, "MouseButton1Click")
print("rating after click:", rating.value)

__fire(chips.chips[2].chip, "MouseButton1Click")
print("chips:", type(chips.value), #chips.value)

__fire(stepper.items[2].click, "MouseButton1Click")
print("stepper:", stepper.value)

__fire(dropdown.trigger, "MouseButton1Click")
print("dropdown menu open:", dropdown.menu ~= nil)
if dropdown.menu then
	print("dropdown rows:", #dropdown.rows)
	__fire(dropdown.rows[2].row, "MouseButton1Click")
	print("dropdown after pick:", tostring(dropdown.value))
end

__fire(multi.trigger, "MouseButton1Click")
if multi.menu then
	__fire(multi.rows[1].row, "MouseButton1Click")
	print("multi value count:", #multi.value)
end

__fire(color.swatch, "MouseButton1Click")
print("color dialog open:", color.dialog ~= nil)
if color.dialog then
	color.dialog:Destroy()
	color.dialog = nil
end

__fire(keybind.trigger, "MouseButton1Click")
print("keybind recording:", keybind.recording)
__fire(UserInputService, "InputBegan", { UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.F })
print("keybind value:", tostring(keybind.value))

__fire(input.textbox, "Focused")
input.textbox.Text = "typed value"
print("input value:", input.value)

__fire(paragraph.main, "MouseButton1Click")

console:write("first line", "info")
console:write("second line", "warn")
print("console lines:", console:getText())

code:Set("local x = 1")
image:SetImage("rbxassetid://2")
uploader:setSource("rbxassetid://123")
print("uploader value:", tostring(uploader.value))

section:setExpanded(false)
print("section expanded:", section.expanded)
section:setExpanded(true)
print("section expanded:", section.expanded)

tab:setTitle("Renamed")
print("tab title:", tab.label.Text)

print("--- second tab ---")
local second = window:createTab({ Title = "Second", Icon = "settings" })
local secondSection = second:createSection({ Title = "Section 2" })
secondSection:createToggle({ Title = "Second toggle", Value = true })

window:selectTab(second)
print("selected:", window.selectedTab.name)
window:selectTab(tab)
print("selected:", window.selectedTab.name)

print("--- layout ---")
do
	local page = tab.page
	local canvas = page.CanvasSize
	local contentWidth, contentHeight = __size(button.main)
	print("page canvas: " .. tostring(canvas.X.Offset) .. "x" .. tostring(canvas.Y.Offset))
	print("element size: " .. tostring(contentWidth) .. "x" .. tostring(contentHeight))
	print("element position: y=" .. tostring(button.main.Position.Y.Offset))
	print("nav canvas: " .. tostring(window.navList.CanvasSize.Y.Offset))
	for index, entry in ipairs(window.tabs) do
		print("tab " .. index .. " item y=" .. tostring(entry.item.Position.Y.Offset) .. " visible=" .. tostring(entry.page.Visible))
	end
	assert(canvas.X.Offset > 0, "page canvas width must be positive")
	assert(canvas.Y.Offset > 0, "page canvas height must be positive")
	assert(contentWidth > 0, "element width must be positive")
	assert(window.navList.CanvasSize.Y.Offset > 0, "nav canvas height must be positive")

	local codeCanvas = code.scroller.CanvasSize.Y.Offset
	local consoleCanvas = console.scroller.CanvasSize.Y.Offset
	local stepperCanvas = stepper.scroller.CanvasSize.X.Offset
	__fire(dropdown.trigger, "MouseButton1Click")
	local dropdownCanvas = dropdown.menuList.CanvasSize.Y.Offset
	print("code canvas: " .. tostring(codeCanvas))
	print("console canvas: " .. tostring(consoleCanvas))
	print("dropdown canvas: " .. tostring(dropdownCanvas))
	print("stepper canvas: " .. tostring(stepperCanvas))
	assert(codeCanvas > 0, "code canvas must have height")
	assert(consoleCanvas > 0, "console canvas must have height")
	assert(dropdownCanvas > 0, "dropdown canvas must have height")
	assert(stepperCanvas > 0, "stepper canvas must have width")
	print("layout assertions passed")
end

print("--- theme and layout ---")
window:setTheme({ mode = "light" })
print("theme mode:", window.theme.mode)
window:setAccent(Color3.fromRGB(0, 100, 200))
print("seed:", Sonar.Palette.toHex(window.theme.seed))
window:setTheme("Material")
window:setLayout("top")
print("layout:", window.layout)
window:setLayout("sidebar")

window:setLanguage("ru")
print("language:", window.locale.current)
window:setLanguage("en")

window:notify({ Title = "Hi", Content = "There", Icon = "check" })
window:popup({ Title = "Dialog", Content = "Body", Buttons = { { Title = "OK" } } })

print("saveConfig:", tostring(window:saveConfig()))
print("loadConfig:", tostring(window:loadConfig()))
print("instances built:", __count(window.screen))
print("flags registered:", window.flags.toggleFlag ~= nil, window.flags.sliderFlag ~= nil)
print("SMOKE TEST PASSED")
