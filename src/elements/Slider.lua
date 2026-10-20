local Element = require(script.Parent.Parent.core.Element)
local Creator = require(script.Parent.Parent.core.Creator)
local Motion = require(script.Parent.Parent.core.Motion)
local Variables = require(script.Parent.Parent.core.Variables)

local Slider = {}

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
	handle.second = props.SecondValue

	function handle:_build(parentFrame, order)
		local window = self.window
		local theme = window.theme
		Creator.window = window

		local main = Creator.new("Frame", {
			Name = "Slider",
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, 68),
			BackgroundTransparency = 1,
			Parent = parentFrame,
		})
		self.main = main

		local title = Creator.new("TextLabel", {
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(1, -80, 0, 20),
			BackgroundTransparency = 1,
			Font = theme.fonts.bold,
			Text = props.Title or "",
			TextColor3 = theme.colors.onSurface,
			TextSize = theme.type.titleMedium.size,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = main,
		}, { TextColor3 = "onSurface" })
		self.title = title

		local valueLabel = Creator.new("TextLabel", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 0),
			Size = UDim2.fromOffset(72, 20),
			BackgroundTransparency = 1,
			Font = theme.fonts.bold,
			Text = "",
			TextColor3 = theme.colors.primary,
			TextSize = theme.type.labelLarge.size,
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = main,
		}, { TextColor3 = "primary" })
		self.valueLabel = valueLabel

		local trackArea = Creator.new("Frame", {
			Position = UDim2.new(0, 0, 0, 40),
			Size = UDim2.new(1, 0, 0, 24),
			BackgroundTransparency = 1,
			Parent = main,
		})
		self.trackArea = trackArea

		local track = Creator.new("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			Size = UDim2.new(1, 0, 0, 4),
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

		local handleSize = 20
		local knob = Creator.new("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			Size = UDim2.fromOffset(handleSize, handleSize),
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

		local dragging = false

		self._inputConnection = Element.connect(self, Variables.services.UserInputService.InputChanged, function(changed)
			if not dragging then
				return
			end
			if changed.UserInputType == Enum.UserInputType.MouseMovement or changed.UserInputType == Enum.UserInputType.Touch then
				applyMouse(changed)
			end
		end)

		Element.connect(self, trackArea.InputBegan, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				Motion.tween(knobRing, { Transparency = 0.6 }, theme.motion.short)
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
			Motion.tween(knob, { Size = UDim2.fromOffset(20, 20) }, theme.motion.short)
			if props.Callback then
				task.spawn(props.Callback, self.value, false)
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
