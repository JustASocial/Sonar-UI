local Creator = require(script.Parent.Creator)
local Motion = require(script.Parent.Motion)
local Icons = require(script.Parent.Parent.icons.Init)

local Popup = {}

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
		ZIndex = 100,
		Parent = overlay,
	}, { BackgroundColor3 = "scrim" })

	local dialog = Creator.new("Frame", {
		Name = "Dialog",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = props.Size or UDim2.fromOffset(360, 220),
		BackgroundColor3 = theme.colors.surfaceContainerHigh,
		BorderSizePixel = 0,
		ZIndex = 101,
		Parent = scrim,
	}, { BackgroundColor3 = "surfaceContainerHigh" })

	Creator.new("UICorner", {
		CornerRadius = theme.shape.dialog,
		Parent = dialog,
	})

	local layout = Creator.new("UIListLayout", {
		Padding = UDim.new(0, 12),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
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
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 24, 0, 24),
			Size = UDim2.fromOffset(24, 24),
			BackgroundTransparency = 1,
			Image = Icons.image(props.Icon) or "",
			ImageColor3 = theme.colors.onSurfaceVariant,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 102,
			Parent = dialog,
		}, { ImageColor3 = "onSurfaceVariant" })
		icon.LayoutOrder = 1
	end

	local title = Creator.new("TextLabel", {
		Position = UDim2.new(0, 24, 0, 24),
		Size = UDim2.new(1, -48, 0, 28),
		BackgroundTransparency = 1,
		Font = theme.fonts.bold,
		Text = props.Title or "",
		TextColor3 = theme.colors.onSurface,
		TextSize = theme.type.headlineSmall.size,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		ZIndex = 102,
		Parent = dialog,
	}, { TextColor3 = "onSurface" })
	title.LayoutOrder = 2

	local content = nil
	if props.Content then
		content = Creator.new("TextLabel", {
			Size = UDim2.new(1, -48, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Font = theme.fonts.regular,
			Text = props.Content,
			TextColor3 = theme.colors.onSurfaceVariant,
			TextSize = theme.type.bodyMedium.size,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextWrapped = true,
			ZIndex = 102,
			Parent = dialog,
		}, { TextColor3 = "onSurfaceVariant" })
		content.LayoutOrder = 3
	end

	local actions = Creator.new("Frame", {
		Size = UDim2.new(1, -48, 0, 40),
		BackgroundTransparency = 1,
		ZIndex = 102,
		Parent = dialog,
	})
	actions.LayoutOrder = 4

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
		local variant = spec.Variant or "text"
		local button = Creator.new("TextButton", {
			Size = UDim2.fromOffset(0, 40),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Text = spec.Title or "OK",
			Font = theme.fonts.bold,
			TextColor3 = variant == "primary" and theme.colors.primary or theme.colors.onSurfaceVariant,
			TextSize = theme.type.labelLarge.size,
			LayoutOrder = index,
			ZIndex = 102,
			Parent = actions,
		}, { TextColor3 = variant == "primary" and "primary" or "onSurfaceVariant" })

		Creator.new("UIPadding", {
			PaddingLeft = UDim.new(0, 16),
			PaddingRight = UDim.new(0, 16),
			Parent = button,
		})

		if variant == "filled" then
			Creator.new("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = theme.colors.outlineVariant,
				Transparency = 0,
				Thickness = 1,
				Parent = button,
			}, { Color = "outlineVariant" })
		end

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

	Motion.tween(scrim, { BackgroundTransparency = 0.55 }, theme.motion.emphasizedDecelerate)
	Motion.tween(dialog, { BackgroundTransparency = 0 }, theme.motion.emphasizedDecelerate)

	return {
		Close = close,
		Dialog = dialog,
	}
end

return Popup
