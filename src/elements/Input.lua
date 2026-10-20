local Element = require(script.Parent.Parent.core.Element)
local Creator = require(script.Parent.Parent.core.Creator)
local Motion = require(script.Parent.Parent.core.Motion)

local Input = {}

function Input.new(ctx)
	local props = ctx.props or {}
	local typeName = ctx.typeName or "Input"
	local handle = Element.new({
		typeName = typeName,
		window = ctx.window,
		container = ctx.container,
		props = props,
	})
	handle.value = props.Value or ""

	function handle:_build(parentFrame, order)
		local window = self.window
		local theme = window.theme
		Creator.window = window

		local multiline = typeName == "TextArea"

		local main = Creator.new("Frame", {
			Name = typeName,
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, multiline and 128 or (props.Description and 76 or 60)),
			BackgroundTransparency = 1,
			Parent = parentFrame,
		})
		self.main = main

		local fieldHeight = multiline and 104 or 56
		local field = Creator.new("Frame", {
			Name = "Field",
			Position = UDim2.new(0, 0, 0, multiline and 0 or 8),
			Size = UDim2.new(1, 0, 0, fieldHeight),
			BackgroundColor3 = theme.colors.surfaceContainerHighest,
			BorderSizePixel = 0,
			Parent = main,
		}, { BackgroundColor3 = "surfaceContainerHighest" })
		self.field = field

		Creator.new("UICorner", {
			CornerRadius = theme.shape.field,
			Parent = field,
		})

		local indicator = Creator.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, 0),
			Size = UDim2.new(1, 0, 0, 2),
			BackgroundColor3 = theme.colors.onSurfaceVariant,
			BackgroundTransparency = 0.6,
			BorderSizePixel = 0,
			Parent = field,
		}, { BackgroundColor3 = "onSurfaceVariant" })
		self.indicator = indicator

		local label = Creator.new("TextLabel", {
			Position = UDim2.new(0, 16, 0, multiline and 8 or 20),
			Size = UDim2.new(1, -32, 0, 18),
			BackgroundTransparency = 1,
			Font = theme.fonts.regular,
			Text = props.Title or "",
			TextColor3 = theme.colors.onSurfaceVariant,
			TextSize = theme.type.bodyLarge.size,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = field,
		}, { TextColor3 = "onSurfaceVariant" })
		self.label = label

		local textbox = Creator.new("TextBox", {
			Name = "TextBox",
			Position = UDim2.new(0, 16, 0, multiline and 32 or 24),
			Size = UDim2.new(1, -32, 1, multiline and -40 or -24),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = "",
			PlaceholderText = props.Placeholder or "",
			PlaceholderColor3 = theme.colors.onSurfaceVariant,
			TextColor3 = theme.colors.onSurface,
			TextSize = theme.type.bodyLarge.size,
			Font = theme.fonts.regular,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = multiline and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
			TextWrapped = multiline,
			MultiLine = multiline,
			ClearTextOnFocus = props.ClearOnFocus == true,
			TextEditable = props.Disabled ~= true,
			Parent = field,
		}, { TextColor3 = "onSurface" })
		self.textbox = textbox

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

		local function setFloating(floating)
			if multiline then
				return
			end
			Motion.tween(label, {
				Position = UDim2.new(0, 16, 0, floating and 6 or 20),
				TextSize = floating and theme.type.bodySmall.size or theme.type.bodyLarge.size,
			}, theme.motion.short)
		end

		Element.connect(self, textbox.Focused, function()
			setFloating(true)
			Motion.tween(indicator, { BackgroundColor3 = theme.colors.primary, BackgroundTransparency = 0 }, theme.motion.short)
		end)

		Element.connect(self, textbox.FocusLost, function()
			if textbox.Text == "" then
				setFloating(false)
			end
			Motion.tween(indicator, { BackgroundColor3 = theme.colors.onSurfaceVariant, BackgroundTransparency = 0.6 }, theme.motion.short)
			self:_commit()
		end)

		Element.connect(self, textbox:GetPropertyChangedSignal("Text"), function()
			local text = textbox.Text
			if props.Numeric and text ~= "" then
				local cleaned = text:gsub("[^%d%.%-]", "")
				if cleaned ~= text then
					textbox.Text = cleaned
					text = cleaned
				end
			end
			if props.MaxLength and #text > props.MaxLength then
				textbox.Text = string.sub(text, 1, props.MaxLength)
				text = textbox.Text
			end
			if text ~= "" then
				setFloating(true)
			end
			self.value = text
			if props.OnChange then
				task.spawn(props.OnChange, text)
			end
		end)

		self:Set(self.value, true)
	end

	function handle:_commit()
		if self.props.Callback then
			task.spawn(self.props.Callback, self.value)
		end
		if self.window and self.flag then
			self.window:_persist(self)
		end
	end

	function handle:Set(value, skipCallback)
		value = tostring(value or "")
		self.value = value
		if self.textbox then
			self.textbox.Text = value
			if value ~= "" then
				self.label.Position = UDim2.new(0, 16, 0, 6)
				self.label.TextSize = self.window.theme.type.bodySmall.size
			else
				self.label.Position = UDim2.new(0, 16, 0, 20)
				self.label.TextSize = self.window.theme.type.bodyLarge.size
			end
		end
		if not skipCallback and self.props.Callback then
			task.spawn(self.props.Callback, value)
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
		self.field.BackgroundColor3 = theme.colors.surfaceContainerHighest
		self.textbox.TextColor3 = theme.colors.onSurface
		self.label.TextColor3 = theme.colors.onSurfaceVariant
		self.indicator.BackgroundColor3 = theme.colors.onSurfaceVariant
	end

	function handle:_destroy()
		Element.destroy(self)
	end

	return handle
end

return { new = Input.new }
