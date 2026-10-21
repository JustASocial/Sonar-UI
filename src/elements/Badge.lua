local Element = require(script.Parent.Parent.core.Element)
local Creator = require(script.Parent.Parent.core.Creator)
local Motion = require(script.Parent.Parent.core.Motion)
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
			Size = UDim2.new(0, 0, 0, 26),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = theme.colors[variant.fill],
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
			Parent = parentFrame,
		}, { BackgroundColor3 = variant.fill })
		self.main = main

		Creator.new("UICorner", {
			CornerRadius = UDim.new(1, 0),
			Parent = main,
		})

		local row = Creator.new("Frame", {
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			Parent = main,
		})

		Creator.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Parent = row,
		})

		if props.Icon then
			local icon = Creator.new("ImageLabel", {
				Size = UDim2.fromOffset(14, 14),
				BackgroundTransparency = 1,
				Image = Icons.image(props.Icon) or "",
				ImageColor3 = theme.colors[variant.text],
				ScaleType = Enum.ScaleType.Fit,
				LayoutOrder = 0,
				Parent = row,
			}, { ImageColor3 = variant.text })
			self.icon = icon
		end

		local label = Creator.new("TextLabel", {
			Size = UDim2.new(0, 0, 0, 18),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			Font = theme.fonts.bold,
			Text = props.Text or "",
			TextColor3 = theme.colors[variant.text],
			TextSize = theme.type.labelMedium.size,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		}, { TextColor3 = variant.text })
		self.label = label

		Creator.new("UIPadding", {
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
			Parent = main,
		})
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
