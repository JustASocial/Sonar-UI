local Element = require(script.Parent.Parent.core.Element)
local Row = require(script.Parent.Parent.core.Row)
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

		Row.build(self, {
			title = props.Title,
			description = props.Description,
			icon = props.Icon,
			controlWidth = TRACK_WIDTH,
			parent = parentFrame,
			order = order,
		})

		local content = self.content

		local track = Creator.new("TextButton", {
			Name = "Switch",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(TRACK_WIDTH, TRACK_HEIGHT),
			BackgroundColor3 = theme.colors.surfaceContainerHighest,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			Parent = content,
		}, { BackgroundColor3 = "surfaceContainerHighest" })
		self.track = track

		Creator.new("UICorner", {
			CornerRadius = UDim.new(1, 0),
			Parent = track,
		})

		local state = Creator.new("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = theme.colors.onSurface,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Parent = track,
		}, { BackgroundColor3 = "onSurface" })
		self.state = state

		local stroke = Creator.new("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = theme.colors.outline,
			Transparency = 0,
			Thickness = 2,
			Parent = track,
		}, { Color = "outline" })
		self.stroke = stroke

		local knob = Creator.new("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 8, 0.5, 0),
			Size = UDim2.fromOffset(16, 16),
			BackgroundColor3 = theme.colors.outline,
			BorderSizePixel = 0,
			Parent = track,
		}, { BackgroundColor3 = "outline" })
		self.knob = knob

		Creator.new("UICorner", {
			CornerRadius = UDim.new(1, 0),
			Parent = knob,
		})

		local knobIcon = nil
		if props.Icon then
			knobIcon = Creator.new("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(14, 14),
				BackgroundTransparency = 1,
				Image = Icons.image(props.Icon) or "",
				ImageColor3 = theme.colors.surfaceContainerHighest,
				ScaleType = Enum.ScaleType.Fit,
				Parent = knob,
			}, { ImageColor3 = "surfaceContainerHighest" })
			self.knobIcon = knobIcon
		end

		Element.connect(self, track.MouseEnter, function()
			Motion.tween(state, { BackgroundTransparency = 1 - theme.state.hover }, theme.motion.short)
		end)
		Element.connect(self, track.MouseLeave, function()
			Motion.tween(state, { BackgroundTransparency = 1 }, theme.motion.short)
		end)
		Element.connect(self, track.InputBegan, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				Motion.tween(state, { BackgroundTransparency = 1 - theme.state.pressed }, theme.motion.short4)
			end
		end)
		Element.connect(self, track.InputEnded, function()
			Motion.tween(state, { BackgroundTransparency = 1 - theme.state.hover }, theme.motion.short4)
		end)
		Element.connect(self, track.MouseButton1Click, function()
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
		local token = animate and theme.motion.standard or theme.motion.short

		Motion.tween(self.track, {
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
		if not skipCallback and props.Callback then
			task.spawn(props.Callback, value)
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
		Row.refreshTheme(self)
		self:_render(false)
	end

	function handle:_destroy()
		Element.destroy(self)
	end

	return handle
end

return { new = Toggle.new }
