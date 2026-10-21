local Creator = require(script.Parent.Creator)
local Icons = require(script.Parent.Parent.icons.Init)

local Row = {}

Row.Metrics = {
	padLeft = 16,
	padRight = 16,
	iconSize = 22,
	iconGap = 14,
	gap = 14,
	height = 52,
	heightTall = 68,
	titleSize = 15,
	descSize = 12,
}

function Row.build(handle, options)
	local window = handle.window
	local theme = window.theme
	local metrics = Row.Metrics

	local title = options.title
	local description = options.description
	local iconName = options.icon
	local controlWidth = options.controlWidth or 0
	local height = options.height
	if not height then
		height = description and metrics.heightTall or metrics.height
	end

	local main = Creator.new("Frame", {
		Name = handle.__type,
		LayoutOrder = options.order or 0,
		Size = UDim2.new(1, 0, 0, height),
		BackgroundTransparency = 1,
		Parent = options.parent,
	})
	handle.main = main

	local stateLayer = Creator.new("Frame", {
		Name = "StateLayer",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = theme.colors.onSurface,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = main,
	}, { BackgroundColor3 = "onSurface" })
	Creator.new("UICorner", {
		CornerRadius = theme.shape.element,
		Parent = stateLayer,
	})
	handle.stateLayer = stateLayer

	local left = metrics.padLeft
	local icon = nil
	if iconName then
		icon = Creator.new("ImageLabel", {
			Name = "Icon",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, metrics.padLeft, 0.5, 0),
			Size = UDim2.fromOffset(metrics.iconSize, metrics.iconSize),
			BackgroundTransparency = 1,
			Image = Icons.image(iconName) or "",
			ImageColor3 = theme.colors.onSurfaceVariant,
			ScaleType = Enum.ScaleType.Fit,
			Parent = main,
		}, { ImageColor3 = "onSurfaceVariant" })
		handle.icon = icon
		left = metrics.padLeft + metrics.iconSize + metrics.iconGap
	end

	local reserved = left + metrics.padRight + controlWidth
	if controlWidth > 0 then
		reserved = reserved + metrics.gap
	end
	local textWidth = math.max(40, reserved - left)

	local titleLabel = nil
	if title ~= nil and title ~= "" then
		titleLabel = Creator.new("TextLabel", {
			Name = "Title",
			Position = UDim2.new(0, left, 0, description and 12 or 0),
			Size = UDim2.new(0, textWidth, 0, 20),
			BackgroundTransparency = 1,
			Font = theme.fonts.medium,
			Text = title,
			TextColor3 = theme.colors.onSurface,
			TextSize = metrics.titleSize,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = main,
		}, { TextColor3 = "onSurface" })
		handle.title = titleLabel
	end

	local descLabel = nil
	if description ~= nil and description ~= "" then
		descLabel = Creator.new("TextLabel", {
			Name = "Description",
			Position = UDim2.new(0, left, 0, 36),
			Size = UDim2.new(0, textWidth, 0, 18),
			BackgroundTransparency = 1,
			Font = theme.fonts.regular,
			Text = description,
			TextColor3 = theme.colors.onSurfaceVariant,
			TextSize = metrics.descSize,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = main,
		}, { TextColor3 = "onSurfaceVariant" })
		handle.desc = descLabel
	end

	local content = nil
	if controlWidth > 0 then
		content = Creator.new("Frame", {
			Name = "Content",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -metrics.padRight, 0.5, 0),
			Size = UDim2.fromOffset(controlWidth, math.max(36, height - 8)),
			BackgroundTransparency = 1,
			Parent = main,
		})
		handle.content = content
	end

	return main, content
end

function Row.refreshTheme(handle)
	local theme = handle.window.theme
	if handle.title then
		handle.title.TextColor3 = theme.colors.onSurface
	end
	if handle.desc then
		handle.desc.TextColor3 = theme.colors.onSurfaceVariant
	end
	if handle.icon then
		handle.icon.ImageColor3 = theme.colors.onSurfaceVariant
	end
end

return Row
