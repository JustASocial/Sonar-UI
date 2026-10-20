local Element = require(script.Parent.Parent.core.Element)
local Creator = require(script.Parent.Parent.core.Creator)
local Motion = require(script.Parent.Parent.core.Motion)
local Variables = require(script.Parent.Parent.core.Variables)

local Keybind = {}

local function keyName(key)
	if key == nil then
		return "None"
	end
	return key.Name
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

		local main = Creator.new("Frame", {
			Name = "Keybind",
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, props.Description and 76 or 60),
			BackgroundTransparency = 1,
			Parent = parentFrame,
		})
		self.main = main

		local trigger = Creator.new("TextButton", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 8),
			Size = UDim2.fromOffset(150, 44),
			BackgroundColor3 = theme.colors.surfaceContainerHigh,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			Parent = main,
		}, { BackgroundColor3 = "surfaceContainerHigh" })
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
			Font = theme.fonts.bold,
			Text = "None",
			TextColor3 = theme.colors.onSurface,
			TextSize = theme.type.bodyMedium.size,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = trigger,
		}, { TextColor3 = "onSurface" })
		self.label = label

		if props.Description then
			local desc = Creator.new("TextLabel", {
				Position = UDim2.new(0, 0, 1, -20),
				Size = UDim2.new(1, 0, 0, 18),
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
		Motion.tween(self.state, { BackgroundTransparency = 1 - theme.state.pressed }, theme.motion.short4)

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
				self:Set(Enum.KeyCode.MouseButton1, true)
				self:_stopRecording()
			elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
				self:Set(Enum.KeyCode.MouseButton2, true)
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
			Motion.tween(self.state, { BackgroundTransparency = 1 }, self.window.theme.motion.short4)
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
		self.trigger.BackgroundColor3 = theme.colors.surfaceContainerHigh
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
