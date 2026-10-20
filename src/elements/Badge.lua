local Element = require(script.Parent.Parent.core.Element)
local Creator = require(script.Parent.Parent.core.Creator)
local Icons = require(script.Parent.Parent.icons.Init)

local Badge = {}

local VARIANTS = {
	neutral = { fill = "surfaceContainerHighest", text = "onSurfaceVariant" },
	primary = { fill = "primaryContainer", text = "onPrimaryContainer" },
	success = { fill = "tertiaryContainer", text = "onTertiaryContainer" },
	error = { fill = "errorContainer", text = "onErrorContainer" },
}

function Badge.new(ctx)
	local props = ctx.props or {}
	local handle = Element.new({
		typeName = "Badge",
		window = ctx.window,
		container = ctx.container,
		props = props,
	})

	function handle:_build(parentFrame, order)
		local window = self.window
		local theme = window.theme
		Creator.window = window

		local variant = VARIANTS[props.Variant] or VARIANTS.neutral

		local main = Creator.new("Frame", {
			Name = "Badge",
			LayoutOrder = order,
			Size = UDim2.new(0, 0, 0, 24),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = theme.colors[variant.fill],
			BorderSizePixel = 0,
			Parent = parentFrame,
		}, { BackgroundColor3 = variant.fill })
		self.main = main

		Creator.new("UICorner", {
			CornerRadius = UDim.new(1, 0),
			Parent = main,
		})

		Creator.new("UIPadding", {
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
			Parent = main,
		})

		local icon = nil
		if props.Icon then
			icon = Creator.new("ImageLabel", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 10, 0.5, 0),
				Size = UDim2.fromOffset(14, 14),
				BackgroundTransparency = 1,
				Image = Icons.image(props.Icon) or "",
				ImageColor3 = theme.colors[variant.text],
				ScaleType = Enum.ScaleType.Fit,
				Parent = main,
			}, { ImageColor3 = variant.text })
			self.icon = icon
		end

		local label = Creator.new("TextLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, icon and 30 or 10, 0.5, 0),
			Size = UDim2.new(1, icon and -40 or -20, 1, 0),
			BackgroundTransparency = 1,
			Font = theme.fonts.bold,
			Text = props.Text or "",
			TextColor3 = theme.colors[variant.text],
			TextSize = theme.type.labelSmall.size,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = main,
		}, { TextColor3 = variant.text })
		self.label = label
	end

	function handle:setText(text)
		if self.label then
			self.label.Text = text
		end
	end

	function handle:_refreshTheme()
		if not self.main then
			return
		end
		local theme = self.window.theme
		local variant = VARIANTS[self.props.Variant] or VARIANTS.neutral
		self.main.BackgroundColor3 = theme.colors[variant.fill]
		self.label.TextColor3 = theme.colors[variant.text]
		if self.icon then
			self.icon.ImageColor3 = theme.colors[variant.text]
		end
	end

	function handle:_destroy()
		Element.destroy(self)
	end

	return handle
end

return { new = Badge.new }
