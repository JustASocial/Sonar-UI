local Element = require(script.Parent.Parent.core.Element)
local Row = require(script.Parent.Parent.core.Row)
local Creator = require(script.Parent.Parent.core.Creator)
local Motion = require(script.Parent.Parent.core.Motion)
local Variables = require(script.Parent.Parent.core.Variables)

local Keybind = {}

local PILL_WIDTH = 120
local PILL_HEIGHT = 40

local function keyName(key)
	if key == nil then
		return "None"
	end
	if type(key) == "string" then
		return key
	end
	if typeof(key) == "EnumItem" then
		return key.Name
	end
	return tostring(key)
end

function Keybind.new(ctx)
	local props = ctx.props or {}
	local handle = Element.new({
		typeName = "Keybind",
		window = ctx.window,
		container = ctx.container,
		props = props,
	})
	handle.value = props.Value

	function handle:_build(parentFrame, order)
		local window = self.window
		local theme = window.theme
		Creator.window = window

		Row.build(self, {
			title = props.Title,
			description = props.Description,
			icon = props.Icon,
			controlWidth = PILL_WIDTH,
			parent = parentFrame,
			order = order,
		})

		local content = self.content

		local trigger = Creator.new("TextButton", {
			Name = "Trigger",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(PILL_WIDTH, PILL_HEIGHT),
			BackgroundColor3 = theme.colors.surfaceContainerHighest,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			Parent = content,
		}, { BackgroundColor3 = "surfaceContainerHighest" })
		self.trigger = trigger

		Creator.new("UICorner", {
			CornerRadius = theme.shape.field,
			Parent = trigger,
		})
		Creator.new("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = theme.colors.outlineVariant,
			Transparency = 0,
			Thickness = 1,
			Parent = trigger,
		}, { Color = "outlineVariant" })

		local state = Creator.new("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = theme.colors.onSurface,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Parent = trigger,
		}, { BackgroundColor3 = "onSurface" })
		self.state = state

		local label = Creator.new("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, -16, 1, 0),
			BackgroundTransparency = 1,
			Font = theme.fonts.medium,
			Text = "None",
			TextColor3 = theme.colors.onSurface,
			TextSize = theme.type.bodyMedium.size,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = trigger,
		}, { TextColor3 = "onSurface" })
		self.label = label

		Element.connect(self, trigger.MouseEnter, function()
			Motion.tween(state, { BackgroundTransparency = 1 - theme.state.hover }, theme.motion.short)
		end)
		Element.connect(self, trigger.MouseLeave, function()
			Motion.tween(state, { BackgroundTransparency = 1 }, theme.motion.short)
		end)
		Element.connect(self, trigger.MouseButton1Click, function()
			if self.locked then
				return
			end
			self:_beginRecording()
		end)

		self:_updateDisplay()
	end

	function handle:_updateDisplay()
		if not self.label then
			return
		end
		if self.recording then
			self.label.Text = "..."
			self.label.TextColor3 = self.window.theme.colors.primary
		else
			self.label.Text = keyName(self.value)
			self.label.TextColor3 = self.window.theme.colors.onSurface
		end
	end

	function handle:_beginRecording()
		local theme = self.window.theme
		self.recording = true
		self:_updateDisplay()
		Motion.tween(self.state, { BackgroundTransparency = 1 - theme.state.pressed }, theme.motion.short)

		self._recorder = Variables.services.UserInputService.InputBegan:Connect(function(input, processed)
			if processed then
				return
			end
			if input.KeyCode == Enum.KeyCode.Escape then
				self:_stopRecording()
				return
			end
			if input.UserInputType == Enum.UserInputType.Keyboard then
				self:Set(input.KeyCode, true)
				self:_stopRecording()
			elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
				self:Set(Enum.UserInputType.MouseButton1, true)
				self:_stopRecording()
			elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
				self:Set(Enum.UserInputType.MouseButton2, true)
				self:_stopRecording()
			end
		end)
	end

	function handle:_stopRecording()
		self.recording = false
		if self._recorder then
			self._recorder:Disconnect()
			self._recorder = nil
		end
		self:_updateDisplay()
		if self.state then
			Motion.tween(self.state, { BackgroundTransparency = 1 }, self.window.theme.motion.short)
		end
	end

	function handle:Set(value, skipCallback)
		self.value = value
		self:_updateDisplay()
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
		local theme = self.window.theme
		Row.refreshTheme(self)
		self.trigger.BackgroundColor3 = theme.colors.surfaceContainerHighest
		self.label.TextColor3 = theme.colors.onSurface
	end

	function handle:_destroy()
		if self._recorder then
			self._recorder:Disconnect()
			self._recorder = nil
		end
		Element.destroy(self)
	end

	return handle
end

return { new = Keybind.new }
