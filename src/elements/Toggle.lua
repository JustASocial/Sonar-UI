local Element = require(script.Parent.Parent.core.Element)
local Creator = require(script.Parent.Parent.core.Creator)
local Motion = require(script.Parent.Parent.core.Motion)
local Icons = require(script.Parent.Parent.icons.Init)

local Toggle = {}

local TRACK_WIDTH = 52
local TRACK_HEIGHT = 32

function Toggle.new(ctx)
	local props = ctx.props or {}
	local handle = Element.new({
		typeName = "Toggle",
		window = ctx.window,
		container = ctx.container,
		props = props,
	})
	handle.value = props.Value == true

	function handle:_build(parentFrame, order)
		local window = self.window
		local theme = window.theme
		Creator.window = window

		local main = Creator.new("Frame", {
			Name = "Toggle",
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, props.Description and 64 or 48),
			BackgroundTransparency = 1,
			Parent = parentFrame,
		})
		self.main = main

		local title = Creator.new("TextLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 0, 0.5, props.Description and -10 or 0),
			Size = UDim2.new(1, -(TRACK_WIDTH + 32), 1, 0),
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

		if props.Description then
			local desc = Creator.new("TextLabel", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 0, 0.5, 12),
				Size = UDim2.new(1, -(TRACK_WIDTH + 32), 1, 0),
				BackgroundTransparency = 1,
				Font = theme.fonts.regular,
				Text = props.Description,
				TextColor3 = theme.colors.onSurfaceVariant,
				TextSize = theme.type.bodySmall.size,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = main,
			}, { TextColor3 = "onSurfaceVariant" })
			self.desc = desc
		end

		if props.Icon then
			local icon = Creator.new("ImageLabel", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.fromOffset(22, 22),
				BackgroundTransparency = 1,
				Image = Icons.image(props.Icon) or "",
				ImageColor3 = theme.colors.onSurfaceVariant,
				ScaleType = Enum.ScaleType.Fit,
				Parent = main,
			}, { ImageColor3 = "onSurfaceVariant" })
			self.icon = icon
			title.Position = UDim2.new(0, 32, 0.5, props.Description and -10 or 0)
			title.Size = UDim2.new(1, -(TRACK_WIDTH + 64), 1, 0)
			if self.desc then
				self.desc.Position = UDim2.new(0, 32, 0.5, 12)
				self.desc.Size = UDim2.new(1, -(TRACK_WIDTH + 64), 1, 0)
			end
		end

		local switch = Creator.new("TextButton", {
			Name = "Switch",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -16, 0.5, 0),
			Size = UDim2.fromOffset(TRACK_WIDTH, TRACK_HEIGHT),
			BackgroundColor3 = theme.colors.surfaceContainerHighest,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			Parent = main,
		}, { BackgroundColor3 = "surfaceContainerHighest" })
		self.switch = switch

		Creator.new("UICorner", {
			CornerRadius = UDim.new(1, 0),
			Parent = switch,
		})

		local state = Creator.new("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = theme.colors.onSurface,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Parent = switch,
		}, { BackgroundColor3 = "onSurface" })
		self.state = state

		local stroke = Creator.new("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = theme.colors.outline,
			Transparency = 0,
			Thickness = 2,
			Parent = switch,
		}, { Color = "outline" })
		self.stroke = stroke

		local knob = Creator.new("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 8, 0.5, 0),
			Size = UDim2.fromOffset(16, 16),
			BackgroundColor3 = theme.colors.outline,
			BorderSizePixel = 0,
			Parent = switch,
		}, { BackgroundColor3 = "outline" })
		self.knob = knob

		Creator.new("UICorner", {
			CornerRadius = UDim.new(1, 0),
			Parent = knob,
		})

		if props.Icon then
			local knobIcon = Creator.new("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(14, 14),
				BackgroundTransparency = 1,
				Image = Icons.image(props.Icon) or "",
				ImageColor3 = theme.colors.surfaceContainerHighest,
				ScaleType = Enum.ScaleType.Fit,
			}, { ImageColor3 = "surfaceContainerHighest" })
			knobIcon.Parent = knob
			self.knobIcon = knobIcon
		end

		Element.connect(self, switch.MouseEnter, function()
			Motion.tween(state, { BackgroundTransparency = 1 - theme.state.hover }, theme.motion.short4)
		end)
		Element.connect(self, switch.MouseLeave, function()
			Motion.tween(state, { BackgroundTransparency = 1 }, theme.motion.short4)
		end)
		Element.connect(self, switch.InputBegan, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				Motion.tween(state, { BackgroundTransparency = 1 - theme.state.pressed }, theme.motion.short4)
			end
		end)
		Element.connect(self, switch.InputEnded, function()
			Motion.tween(state, { BackgroundTransparency = 1 - theme.state.hover }, theme.motion.short4)
		end)
		Element.connect(self, switch.MouseButton1Click, function()
			if self.locked then
				return
			end
			self:Set(not self.value, true)
		end)

		self:_render()
	end

	function handle:_render(animate)
		local theme = self.window.theme
		local on = self.value == true
		local token = animate and theme.motion.standard or theme.motion.short4

		Motion.tween(self.switch, {
			BackgroundColor3 = on and theme.colors.primary or theme.colors.surfaceContainerHighest,
		}, token)
		Motion.tween(self.stroke, {
			Color = on and theme.colors.primary or theme.colors.outline,
			Transparency = on and 1 or 0,
		}, token)
		Motion.tween(self.knob, {
			Position = UDim2.new(0, on and 4 or 8, 0.5, 0),
			Size = UDim2.fromOffset(on and 24 or 16, on and 24 or 16),
			BackgroundColor3 = on and theme.colors.onPrimary or theme.colors.outline,
		}, token)
		if self.knobIcon then
			Motion.tween(self.knobIcon, {
				ImageColor3 = on and theme.colors.primary or theme.colors.surfaceContainerHighest,
			}, token)
		end
	end

	function handle:Set(value, skipCallback)
		value = value == true
		if self.value == value and self.main then
			return
		end
		self.value = value
		if self.main then
			self:_render(true)
		end
		if not skipCallback and self.props.Callback then
			task.spawn(self.props.Callback, value)
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
		self:_render(false)
	end

	function handle:_destroy()
		Element.destroy(self)
	end

	return handle
end

return { new = Toggle.new }
