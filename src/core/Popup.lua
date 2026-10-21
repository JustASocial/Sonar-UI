local Creator = require(script.Parent.Creator)
local Motion = require(script.Parent.Motion)
local Icons = require(script.Parent.Parent.icons.Init)

local Popup = {}

local function makeButton(parent, theme, spec, order)
	local variant = spec.Variant or "text"
	local button = Creator.new("TextButton", {
		Size = UDim2.new(0, 0, 0, 40),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = variant == "filled" and theme.colors.primary or theme.colors.surfaceContainerHighest,
		BackgroundTransparency = variant == "filled" and 0 or 0,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = spec.Title or "",
		Font = theme.fonts.bold,
		TextColor3 = variant == "filled" and theme.colors.onPrimary or theme.colors.onSurface,
		TextSize = theme.type.labelLarge.size,
		LayoutOrder = order,
		Parent = parent,
	}, {
		BackgroundColor3 = variant == "filled" and "primary" or "surfaceContainerHighest",
		TextColor3 = variant == "filled" and "onPrimary" or "onSurface",
	})

	Creator.new("UICorner", {
		CornerRadius = theme.shape.button,
		Parent = button,
	})

	Creator.new("UIPadding", {
		PaddingLeft = UDim.new(0, 22),
		PaddingRight = UDim.new(0, 22),
		Parent = button,
	})

	local hover = Creator.new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = theme.colors.onSurface,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = button,
	}, { BackgroundColor3 = "onSurface" })

	button.MouseEnter:Connect(function()
		Motion.tween(hover, { BackgroundTransparency = 1 - theme.state.hover }, theme.motion.short)
	end)
	button.MouseLeave:Connect(function()
		Motion.tween(hover, { BackgroundTransparency = 1 }, theme.motion.short)
	end)

	return button
end

function Popup.create(window, props)
	props = props or {}
	local theme = window.theme
	local overlay = window.overlayGui

	local scrim = Creator.new("Frame", {
		Name = "Scrim",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = theme.colors.scrim,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = overlay,
	}, { BackgroundColor3 = "scrim" })

	local dialog = Creator.new("Frame", {
		Name = "Dialog",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = props.Size or UDim2.fromOffset(380, 240),
		BackgroundColor3 = theme.colors.surfaceContainerHigh,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = scrim,
	}, { BackgroundColor3 = "surfaceContainerHigh" })

	Creator.new("UICorner", {
		CornerRadius = theme.shape.dialog,
		Parent = dialog,
	})

	local stack = Creator.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 14),
		Parent = dialog,
	})

	Creator.new("UIPadding", {
		PaddingTop = UDim.new(0, 24),
		PaddingBottom = UDim.new(0, 24),
		PaddingLeft = UDim.new(0, 24),
		PaddingRight = UDim.new(0, 24),
		Parent = dialog,
	})

	local icon = nil
	if props.Icon then
		icon = Creator.new("ImageLabel", {
			Size = UDim2.fromOffset(24, 24),
			BackgroundTransparency = 1,
			Image = Icons.image(props.Icon) or "",
			ImageColor3 = theme.colors.onSurfaceVariant,
			ScaleType = Enum.ScaleType.Fit,
			LayoutOrder = 1,
			Parent = dialog,
		}, { ImageColor3 = "onSurfaceVariant" })
	end

	local title = Creator.new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Font = theme.fonts.bold,
		Text = props.Title or "",
		TextColor3 = theme.colors.onSurface,
		TextSize = theme.type.headlineSmall.size,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		LayoutOrder = 2,
		Parent = dialog,
	}, { TextColor3 = "onSurface" })

	local content = nil
	if props.Content then
		content = Creator.new("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Font = theme.fonts.regular,
			Text = props.Content,
			TextColor3 = theme.colors.onSurfaceVariant,
			TextSize = theme.type.bodyMedium.size,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextWrapped = true,
			LayoutOrder = 3,
			Parent = dialog,
		}, { TextColor3 = "onSurfaceVariant" })
	end

	local actions = Creator.new("Frame", {
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		LayoutOrder = 4,
		Parent = dialog,
	})

	Creator.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = actions,
	})

	local closed = false
	local function close()
		if closed then
			return
		end
		closed = true
		Motion.tween(scrim, { BackgroundTransparency = 1 }, theme.motion.emphasizedAccelerate)
		Motion.tween(dialog, { BackgroundTransparency = 1 }, theme.motion.emphasizedAccelerate)
		task.delay(theme.motion.emphasizedAccelerate.time, function()
			scrim:Destroy()
		end)
	end

	local buttonList = props.Buttons or { { Title = "OK" } }
	for index, spec in ipairs(buttonList) do
		local button = makeButton(actions, theme, spec, index)
		button.MouseButton1Click:Connect(function()
			if spec.Callback then
				task.spawn(spec.Callback)
			end
			if spec.KeepOpen ~= true then
				close()
			end
		end)
	end

	scrim.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and props.Dismissible ~= false then
			close()
		end
	end)

	Motion.tween(scrim, { BackgroundTransparency = 0.6 }, theme.motion.emphasizedDecelerate)
	Motion.tween(dialog, { BackgroundTransparency = 0 }, theme.motion.emphasizedDecelerate)

	return {
		Close = close,
		Dialog = dialog,
	}
end

return Popup
