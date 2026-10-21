local Element = require(script.Parent.Parent.core.Element)
local Row = require(script.Parent.Parent.core.Row)
local Creator = require(script.Parent.Parent.core.Creator)
local Motion = require(script.Parent.Parent.core.Motion)
local Variables = require(script.Parent.Parent.core.Variables)

local Slider = {}

local TRACK_HEIGHT = 4
local HANDLE = 20

function Slider.new(ctx)
	local props = ctx.props or {}
	local handle = Element.new({
		typeName = "Slider",
		window = ctx.window,
		container = ctx.container,
		props = props,
	})
	handle.min = props.Min or 0
	handle.max = props.Max or 100
	handle.step = props.Step or 1
	handle.value = props.Value or props.Default or handle.min

	function handle:_build(parentFrame, order)
		local window = self.window
		local theme = window.theme
		Creator.window = window

		Row.build(self, {
			title = props.Title,
			description = props.Description,
			icon = props.Icon,
			controlWidth = 70,
			parent = parentFrame,
			order = order,
			height = 76,
		})

		local content = self.content

		local valueLabel = Creator.new("TextLabel", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(64, 22),
			BackgroundTransparency = 1,
			Font = theme.fonts.medium,
			Text = "",
			TextColor3 = theme.colors.primary,
			TextSize = theme.type.labelLarge.size,
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = content,
		}, { TextColor3 = "primary" })
		self.valueLabel = valueLabel

		local trackArea = Creator.new("Frame", {
			Name = "TrackArea",
			Position = UDim2.new(0, 0, 1, -20),
			Size = UDim2.new(1, 0, 0, 26),
			BackgroundTransparency = 1,
			Parent = self.main,
		})
		self.trackArea = trackArea

		local track = Creator.new("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			Size = UDim2.new(1, 0, 0, TRACK_HEIGHT),
			BackgroundColor3 = theme.colors.surfaceContainerHighest,
			BorderSizePixel = 0,
			Parent = trackArea,
		}, { BackgroundColor3 = "surfaceContainerHighest" })
		self.track = track

		Creator.new("UICorner", {
			CornerRadius = UDim.new(1, 0),
			Parent = track,
		})

		local fill = Creator.new("Frame", {
			Size = UDim2.new(0, 0, 1, 0),
			BackgroundColor3 = theme.colors.primary,
			BorderSizePixel = 0,
			Parent = track,
		}, { BackgroundColor3 = "primary" })
		self.fill = fill

		Creator.new("UICorner", {
			CornerRadius = UDim.new(1, 0),
			Parent = fill,
		})

		local knob = Creator.new("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			Size = UDim2.fromOffset(HANDLE, HANDLE),
			BackgroundColor3 = theme.colors.primary,
			BorderSizePixel = 0,
			Parent = trackArea,
		}, { BackgroundColor3 = "primary" })
		self.knob = knob

		Creator.new("UICorner", {
			CornerRadius = UDim.new(1, 0),
			Parent = knob,
		})

		local knobRing = Creator.new("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = theme.colors.primary,
			Transparency = 1,
			Thickness = 8,
			Parent = knob,
		}, { Color = "primary" })
		self.knobRing = knobRing

		local dragging = false

		local function applyMouse(input)
			local position = trackArea.AbsolutePosition.X
			local width = trackArea.AbsoluteSize.X
			if width <= 0 then
				return
			end
			local ratio = (input.Position.X - position) / width
			ratio = math.clamp(ratio, 0, 1)
			local raw = self.min + ratio * (self.max - self.min)
			local stepped = self.min + math.floor((raw - self.min) / self.step + 0.5) * self.step
			stepped = math.clamp(stepped, self.min, self.max)
			self:Set(stepped, false, true)
		end

		Element.connect(self, trackArea.InputBegan, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				Motion.tween(knobRing, { Transparency = 0.55 }, theme.motion.short)
				Motion.tween(knob, { Size = UDim2.fromOffset(26, 26) }, theme.motion.short)
				applyMouse(input)
			end
		end)

		Element.connect(self, trackArea.InputEnded, function()
			if not dragging then
				return
			end
			dragging = false
			Motion.tween(knobRing, { Transparency = 1 }, theme.motion.short)
			Motion.tween(knob, { Size = UDim2.fromOffset(HANDLE, HANDLE) }, theme.motion.short)
			if props.Callback then
				task.spawn(props.Callback, self.value, false)
			end
		end)

		self._inputConnection = Element.connect(self, Variables.services.UserInputService.InputChanged, function(input)
			if not dragging then
				return
			end
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				applyMouse(input)
			end
		end)

		self:_render()
	end

	function handle:_format(value)
		local step = self.step
		if step >= 1 then
			return string.format("%d%s", math.floor(value + 0.5), self.props.Suffix or "")
		end
		return string.format("%.2f%s", value, self.props.Suffix or "")
	end

	function handle:_render()
		if not self.main then
			return
		end
		local ratio = (self.value - self.min) / (self.max - self.min)
		ratio = math.clamp(ratio, 0, 1)
		self.fill.Size = UDim2.new(ratio, 0, 1, 0)
		self.knob.Position = UDim2.new(ratio, 0, 0.5, 0)
		self.valueLabel.Text = self:_format(self.value)
	end

	function handle:Set(value, skipCallback, dragging)
		value = math.clamp(tonumber(value) or self.min, self.min, self.max)
		local changed = value ~= self.value
		self.value = value
		if self.main then
			self:_render()
		end
		if changed and not skipCallback and props.Callback then
			task.spawn(props.Callback, value, dragging == true)
		end
		if self.window and self.flag then
			self.window:_persist(self)
		end
	end

	function handle:Get()
		return self.value
	end

	function handle:_refreshTheme()
		if not self.main then
			return
		end
		local theme = self.window.theme
		Row.refreshTheme(self)
		self.fill.BackgroundColor3 = theme.colors.primary
		self.knob.BackgroundColor3 = theme.colors.primary
		self.knobRing.Color = theme.colors.primary
		self.valueLabel.TextColor3 = theme.colors.primary
	end

	function handle:_destroy()
		Element.destroy(self)
	end

	return handle
end

return { new = Slider.new }
