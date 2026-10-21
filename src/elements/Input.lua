local Element = require(script.Parent.Parent.core.Element)
local Creator = require(script.Parent.Parent.core.Creator)
local Motion = require(script.Parent.Parent.core.Motion)
local Icons = require(script.Parent.Parent.icons.Init)

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
		local fieldHeight = multiline and 108 or 56

		local main = Creator.new("Frame", {
			Name = typeName,
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, fieldHeight + (props.Description and 24 or 0)),
			BackgroundTransparency = 1,
			Parent = parentFrame,
		})
		self.main = main

		local field = Creator.new("Frame", {
			Name = "Field",
			Position = UDim2.new(0, 0, 0, 0),
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
			BackgroundTransparency = 0.7,
			BorderSizePixel = 0,
			Parent = field,
		}, { BackgroundColor3 = "onSurfaceVariant" })
		self.indicator = indicator

		local fieldLeft = 16
		if props.Icon then
			local fieldIcon = Creator.new("ImageLabel", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 16, 0.5, 0),
				Size = UDim2.fromOffset(18, 18),
				BackgroundTransparency = 1,
				Image = Icons.image(props.Icon) or "",
				ImageColor3 = theme.colors.onSurfaceVariant,
				ScaleType = Enum.ScaleType.Fit,
				Parent = field,
			}, { ImageColor3 = "onSurfaceVariant" })
			self.fieldIcon = fieldIcon
			fieldLeft = 16 + 18 + 12
		end

		local label = Creator.new("TextLabel", {
			Position = UDim2.new(0, fieldLeft, 0, 18),
			Size = UDim2.new(1, -(fieldLeft + 16), 0, 20),
			BackgroundTransparency = 1,
			Font = theme.fonts.regular,
			Text = props.Placeholder or props.Title or "",
			TextColor3 = theme.colors.onSurfaceVariant,
			TextSize = theme.type.bodyLarge.size,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = field,
		}, { TextColor3 = "onSurfaceVariant" })
		self.label = label

		local textbox = Creator.new("TextBox", {
			Name = "TextBox",
			Position = UDim2.new(0, fieldLeft, 0, multiline and 34 or 24),
			Size = UDim2.new(1, -(fieldLeft + 16), 1, multiline and -42 or -28),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = "",
			PlaceholderText = "",
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
				Position = UDim2.new(0, 2, 0, fieldHeight + 6),
				Size = UDim2.new(1, -4, 0, 18),
				BackgroundTransparency = 1,
				Font = theme.fonts.regular,
				Text = props.Description,
				TextColor3 = theme.colors.onSurfaceVariant,
				TextSize = theme.type.bodySmall.size,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = main,
			}, { TextColor3 = "onSurfaceVariant" })
			self.desc = desc
		end

		local function applyLabel(floating, focused)
			local theme = self.window.theme
			local size = floating and theme.type.labelMedium.size or theme.type.bodyLarge.size
			local top = floating and 6 or (multiline and 12 or 18)
			local text = floating and (props.Title or props.Placeholder or "") or (props.Placeholder or props.Title or "")

			self.label.Text = text
			self.label.TextSize = size
			self.label.TextColor3 = focused and theme.colors.primary or theme.colors.onSurfaceVariant
			self.label.Font = floating and theme.fonts.bold or theme.fonts.regular
			Motion.tween(self.label, {
				Position = UDim2.new(0, fieldLeft, 0, top),
			}, theme.motion.standard)
			self.label.Position = UDim2.new(0, fieldLeft, 0, top)
		end

		Element.connect(self, textbox.Focused, function()
			applyLabel(true, true)
			Motion.tween(indicator, {
				BackgroundColor3 = theme.colors.primary,
				BackgroundTransparency = 0,
			}, theme.motion.standard)
		end)

		Element.connect(self, textbox.FocusLost, function()
			if textbox.Text == "" then
				applyLabel(false, false)
			else
				applyLabel(true, false)
			end
			Motion.tween(indicator, {
				BackgroundColor3 = theme.colors.onSurfaceVariant,
				BackgroundTransparency = 0.7,
			}, theme.motion.standard)
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
				applyLabel(true, false)
			end
			self.value = text
			if props.OnChange then
				task.spawn(props.OnChange, text)
			end
		end)

		applyLabel(self.value ~= "", false)
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
			local floating = value ~= ""
			local theme = self.window.theme
			self.label.Text = floating and (self.props.Title or self.props.Placeholder or "")
				or (self.props.Placeholder or self.props.Title or "")
			self.label.TextSize = floating and theme.type.labelMedium.size or theme.type.bodyLarge.size
			self.label.Font = floating and theme.fonts.bold or theme.fonts.regular
			self.label.Position = UDim2.new(0, 16 + (self.props.Icon and 30 or 0), 0, floating and 6 or 18)
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
		if self.fieldIcon then
			self.fieldIcon.ImageColor3 = theme.colors.onSurfaceVariant
		end
		if self.desc then
			self.desc.TextColor3 = theme.colors.onSurfaceVariant
		end
	end

	function handle:_destroy()
		Element.destroy(self)
	end

	return handle
end

return { new = Input.new }
