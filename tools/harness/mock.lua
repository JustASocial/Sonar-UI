local ok, err = pcall(function()
	return _G
end)
assert(ok)

local enumCache = {}

local function enumProxy(path)
	if enumCache[path] then
		return enumCache[path]
	end
	local t = {}
	enumCache[path] = t
	setmetatable(t, {
		__index = function(_, key)
			return enumProxy(path .. "." .. tostring(key))
		end,
		__tostring = function()
			return path
		end,
	})
	return t
end

Enum = enumProxy("Enum")

local function clamp(v, lo, hi)
	if v < lo then return lo end
	if v > hi then return hi end
	return v
end

Color3 = {}
local Color3Meta = {}
Color3Meta.__index = function(self, key)
	if key == "ToHex" then
		return function(c)
			return string.format("#%02X%02X%02X", math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255))
		end
	end
	return nil
end
function Color3.new(r, g, b)
	return setmetatable({ R = r or 0, G = g or 0, B = b or 0 }, Color3Meta)
end
function Color3.fromRGB(r, g, b)
	return Color3.new(r / 255, g / 255, b / 255)
end
function Color3.fromHex(hex)
	hex = hex:gsub("#", "")
	if #hex == 3 then
		hex = hex:sub(1, 1):rep(2) .. hex:sub(2, 2):rep(2) .. hex:sub(3, 3):rep(2)
	end
	return Color3.new(tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255)
end

Vector2 = {}
function Vector2.new(x, y)
	return { X = x or 0, Y = y or 0 }
end

Vector3 = {}
function Vector3.new(x, y, z)
	return { X = x or 0, Y = y or 0, Z = z or 0 }
end

UDim = {}
function UDim.new(scale, offset)
	return { Scale = scale or 0, Offset = offset or 0 }
end

UDim2 = {}
function UDim2.new(xScale, xOffset, yScale, yOffset)
	return { X = UDim.new(xScale, xOffset), Y = UDim.new(yScale, yOffset) }
end
function UDim2.fromOffset(x, y)
	return UDim2.new(0, x, 0, y)
end
function UDim2.fromScale(x, y)
	return UDim2.new(x, 0, y, 0)
end

NumberSequenceKeypoint = {}
function NumberSequenceKeypoint.new(time, value)
	return { Time = time, Value = value }
end

NumberSequence = {}
function NumberSequence.new(a, b)
	return { Keypoints = { a, b } }
end

ColorSequenceKeypoint = {}
function ColorSequenceKeypoint.new(time, value)
	return { Time = time, Value = value }
end

ColorSequence = {}
function ColorSequence.new(a, b)
	return { Keypoints = { a, b } }
end

local Signal = {}
Signal.__index = Signal
function Signal.new()
	return setmetatable({ connections = {}, fired = false }, Signal)
end
function Signal:Connect(callback)
	local connection = { Connected = true }
	function connection:Disconnect()
		self.Connected = false
	end
	table.insert(self.connections, { callback = callback, connection = connection })
	return connection
end
function Signal:Disconnect()
	self.connections = {}
end
function Signal:Wait()
end
function Signal:Fire(...)
	for _, entry in ipairs(self.connections) do
		if entry.connection.Connected then
			local ok, err = pcall(entry.callback, ...)
			if not ok then
				error("signal callback failed: " .. tostring(err) .. "\n" .. debug.traceback(), 0)
			end
		end
	end
end

local SIGNAL_PROPERTIES = {
	MouseEnter = true,
	MouseLeave = true,
	MouseMoved = true,
	MouseButton1Click = true,
	MouseButton1Down = true,
	MouseButton1Up = true,
	InputBegan = true,
	InputEnded = true,
	Focused = true,
	FocusLost = true,
	TextChanged = true,
	ValueChanged = true,
	TouchPinch = true,
	TouchEnded = true,
}

local layoutPass

local InstanceMeta = {}
local InstanceMethods = {}

function InstanceMethods:IsA(className)
	return self._class == className
end

function InstanceMethods:GetChildren()
	local result = {}
	for _, child in ipairs(self._children) do
		if child.Parent == self then
			table.insert(result, child)
		end
	end
	return result
end

function InstanceMethods:FindFirstChild(name)
	for _, child in ipairs(self:GetChildren()) do
		if child.Name == name then
			return child
		end
	end
	return nil
end

function InstanceMethods:ClearAllChildren()
	for _, child in ipairs(self:GetChildren()) do
		child:Destroy()
	end
end

function InstanceMethods:FindFirstChildOfClass(className)
	for _, child in ipairs(self:GetChildren()) do
		if child._class == className then
			return child
		end
	end
	return nil
end

function InstanceMethods:GetDescendants()
	local result = {}
	local function walk(node)
		for _, child in ipairs(node:GetChildren()) do
			table.insert(result, child)
			walk(child)
		end
	end
	walk(self)
	return result
end

function InstanceMethods:Destroy()
	for _, child in ipairs(self:GetChildren()) do
		child:Destroy()
	end
	self.Parent = nil
end

function InstanceMethods:GetPropertyChangedSignal(name)
	local key = "__sig_" .. name
	if not self._signals[key] then
		self._signals[key] = Signal.new()
	end
	return self._signals[key]
end

local function isSignalKey(key)
	return SIGNAL_PROPERTIES[key] == true
end

InstanceMeta.__index = function(self, key)
	local method = InstanceMethods[key]
	if method then
		return method
	end
	if isSignalKey(key) then
		local sigKey = "__sig_" .. key
		if not self._signals[sigKey] then
			self._signals[sigKey] = Signal.new()
		end
		return self._signals[sigKey]
	end
	if key == "AbsoluteSize" or key == "AbsolutePosition" or key == "AbsoluteCanvasSize" or key == "AbsoluteContentSize" then
		return Vector2.new(400, 400)
	end
	if key == "CanvasPosition" then
		return Vector2.new(0, 0)
	end
	return self._props[key]
end

InstanceMeta.__newindex = function(self, key, value)
	if key == "Parent" then
		local previous = self._props.Parent
		if previous and previous._children then
			for index, child in ipairs(previous._children) do
				if child == self then
					table.remove(previous._children, index)
					break
				end
			end
		end
		self._props.Parent = value
		if value and value._children then
			table.insert(value._children, self)
			layoutPass(value)
		end
		return
	end
	self._props[key] = value
	if key == "Size" or key == "LayoutOrder" then
		local parent = self._props.Parent
		if parent then
			layoutPass(parent)
		end
	end
	local sig = self._signals["__sig_" .. key]
	if sig then
		sig:Fire(value)
	end
	if key == "Text" then
		local textSig = self._signals["__sig_TextChanged"]
		if textSig then
			textSig:Fire(value)
		end
	end
end

Instance = {}

function Instance.new(className)
	local self = setmetatable({}, InstanceMeta)
	rawset(self, "_class", className)
	rawset(self, "_props", {
		Name = className,
		Visible = true,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		TextTransparency = 0,
		ImageTransparency = 0,
		ZIndex = 1,
		LayoutOrder = 0,
		Rotation = 0,
		AbsoluteSize = Vector2.new(400, 400),
	})
	rawset(self, "_children", {})
	rawset(self, "_signals", {})
	if className == "UIPageLayout" then
		self._pageLayoutJump = function(_, page)
			return page
		end
	end
	return self
end

InstanceMeta.__index = function(self, key)
	if key == "JumpToPage" and self._class == "UIPageLayout" then
		return self._pageLayoutJump
	end
	local method = InstanceMethods[key]
	if method then
		return method
	end
	if isSignalKey(key) then
		local sigKey = "__sig_" .. key
		if not self._signals[sigKey] then
			self._signals[sigKey] = Signal.new()
		end
		return self._signals[sigKey]
	end
	if key == "AbsoluteSize" or key == "AbsolutePosition" or key == "AbsoluteCanvasSize" or key == "AbsoluteContentSize" then
		return Vector2.new(400, 400)
	end
	if key == "CanvasPosition" then
		return Vector2.new(0, 0)
	end
	return self._props[key]
end

TweenInfo = {}
function TweenInfo.new(time, style, direction)
	return { Time = time or 0, EasingStyle = style, EasingDirection = direction }
end

local function makeTween(target, props)
	local tween = {}
	tween.Completed = Signal.new()
	function tween:Play()
		for key, value in pairs(props) do
			target[key] = value
		end
		self.Completed:Fire(Enum.EasingStyle.Quad)
	end
	function tween:Cancel()
	end
	return tween
end

TweenService = {
	Create = function(_, target, info, props)
		return makeTween(target, props)
	end,
}

local function makeService(fields)
	local service = {}
	for key, value in pairs(fields or {}) do
		service[key] = value
	end
	return service
end

RunService = makeService({
	RenderStepped = Signal.new(),
	Heartbeat = Signal.new(),
	IsStudio = function()
		return false
	end,
})

UserInputService = makeService({
	InputBegan = Signal.new(),
	InputChanged = Signal.new(),
	InputEnded = Signal.new(),
	GetFocusedTextBox = function()
		return nil
	end,
})

TextService = makeService({
	GetTextBoundsAsync = function(_, params)
		local length = utf8.len(params.Text or "") or #(params.Text or "")
		local size = params.Size or 14
		return { X = length * size * 0.5, Y = size * 1.4 }
	end,
})

HttpService = makeService({
	JSONEncode = function(_, value)
		return "{__mock:true}"
	end,
	JSONDecode = function(_, value)
		return nil
	end,
	GenerateGUID = function()
		return "00000000-0000-0000-0000-000000000000"
	end,
})

local playerGui = Instance.new("Folder")
playerGui.Name = "PlayerGui"

local localPlayer = makeService({
	PlayerGui = playerGui,
	Name = "Player",
	UserId = 1,
	WaitForChild = function(_, name)
		if name == "PlayerGui" then
			return playerGui
		end
		return nil
	end,
	GetPropertyChangedSignal = function()
		return Signal.new()
	end,
})

Players = makeService({
	LocalPlayer = localPlayer,
	GetPlayers = function()
		return { localPlayer }
	end,
})

LocalizationService = makeService({
	SystemLocaleId = "en",
})

GuiService = makeService({})
ContentProvider = makeService({})

game = makeService({
	HttpGet = function(_, url)
		return "-- stub source for " .. tostring(url)
	end,
	GetService = function(_, name)
		if name == "Players" then return Players end
		if name == "UserInputService" then return UserInputService end
		if name == "RunService" then return RunService end
		if name == "TweenService" then return TweenService end
		if name == "TextService" then return TextService end
		if name == "HttpService" then return HttpService end
		if name == "GuiService" then return GuiService end
		if name == "ContentProvider" then return ContentProvider end
		if name == "LocalizationService" then return LocalizationService end
		return makeService({})
	end,
})

task = {
	spawn = function(fn, ...)
		local args = table.pack(...)
		local thread = coroutine.create(function()
			fn(table.unpack(args, 1, args.n))
		end)
		local ok, err = coroutine.resume(thread)
		if not ok then
			error(err, 0)
		end
		return thread
	end,
	delay = function(_, fn, ...)
		return task.spawn(fn, ...)
	end,
	defer = function(fn, ...)
		return task.spawn(fn, ...)
	end,
	wait = function()
		return 0
	end,
	cancel = function()
	end,
}

local LAYOUT_IGNORED = {
	UIListLayout = true,
	UIGridLayout = true,
	UIPadding = true,
	UISizeConstraint = true,
	UIGradient = true,
	UICorner = true,
	UIStroke = true,
	UIPageLayout = true,
}

local function resolveAxis(udim, parentAbsolute)
	if udim.Scale == 1 then
		return parentAbsolute
	end
	return udim.Scale * parentAbsolute + udim.Offset
end

local function resolveSize(instance)
	local parentWidth, parentHeight = 400, 400
	local parent = instance.Parent
	if parent and parent._props and parent._props.Size then
		local size = parent._props.Size
		parentWidth = resolveAxis(size.X, parent.AbsoluteSize.X)
		parentHeight = resolveAxis(size.Y, parent.AbsoluteSize.Y)
	end
	local size = instance._props.Size
	if not size then
		return 0, 0
	end
	return resolveAxis(size.X, parentWidth), resolveAxis(size.Y, parentHeight)
end

layoutPass = function(parent)
	local layout = parent:FindFirstChildOfClass("UIListLayout")
	if not layout then
		return
	end
	local horizontal = layout._props.FillDirection == Enum.FillDirection.Horizontal
	local padding = layout._props.Padding or { Scale = 0, Offset = 0 }
	local gap = padding.Offset
	local x, y = 0, 0
	local maxX, maxY = 0, 0

	local children = {}
	for _, child in ipairs(parent:GetChildren()) do
		if not LAYOUT_IGNORED[child._class] then
			table.insert(children, child)
		end
	end
	table.sort(children, function(a, b)
		return (a._props.LayoutOrder or 0) < (b._props.LayoutOrder or 0)
	end)

	for _, child in ipairs(children) do
		local width, height = resolveSize(child)
		child._props.Position = {
			X = { Scale = 0, Offset = horizontal and x or 0 },
			Y = { Scale = 0, Offset = horizontal and 0 or y },
		}
		if horizontal then
			x = x + width + gap
			maxX = math.max(maxX, x)
			maxY = math.max(maxY, height)
		else
			y = y + height + gap
			maxX = math.max(maxX, width)
			maxY = math.max(maxY, y)
		end
	end

	layout._props.AbsoluteContentSize = Vector2.new(maxX, maxY)
	local sig = layout._signals["__sig_AbsoluteContentSize"]
	if sig then
		sig:Fire(layout._props.AbsoluteContentSize)
	end
end

function __size(instance)
	return resolveSize(instance)
end

function __layout(parent)
	if parent then
		layoutPass(parent)
	end
end

function __fire(target, signalName, ...)
	local direct = target[signalName]
	if type(direct) == "table" and direct.connections then
		direct:Fire(...)
		return
	end
	if target._signals then
		local sig = target._signals["__sig_" .. signalName]
		if sig then
			sig:Fire(...)
		end
	end
end

loadstring = function(source)
	return function()
		return __SONAR_LIB__
	end
end

function __count(root)
	local total = 0
	local function walk(node)
		for _, child in ipairs(node:GetChildren()) do
			total = total + 1
			walk(child)
		end
	end
	walk(root)
	return total
end
