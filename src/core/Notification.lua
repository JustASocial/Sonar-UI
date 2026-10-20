local Creator = require(script.Parent.Creator)
local Motion = require(script.Parent.Motion)
local Icons = require(script.Parent.Parent.icons.Init)

local Notification = {}

local QUEUE = {}

function Notification.create(window, props)
	props = props or {}
	local theme = window.theme
	local overlay = window.overlayGui

	local container = Creator.new("Frame", {
		Name = "Notification",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -24),
		Size = UDim2.new(0, 420, 0, 64),
		BackgroundTransparency = 1,
		Parent = overlay,
	})

	local surface = Creator.new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = theme.colors.inverseSurface,
		BorderSizePixel = 0,
		Parent = container,
	}, { BackgroundColor3 = "inverseSurface" })
	Creator.new("UICorner", {
		CornerRadius = theme.shape.snackbar,
		Parent = surface,
	})
	Creator.new("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = theme.colors.inverseOnSurface,
		Transparency = 0.85,
		Thickness = 1,
		Parent = surface,
	}, { Color = "inverseOnSurface" })

	local icon = nil
	local left = 16
	if props.Icon then
		icon = Creator.new("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 16, 0.5, 0),
			Size = UDim2.fromOffset(20, 20),
			BackgroundTransparency = 1,
			Image = Icons.image(props.Icon) or "",
			ImageColor3 = theme.colors.inverseOnSurface,
			ScaleType = Enum.ScaleType.Fit,
			Parent = surface,
		}, { ImageColor3 = "inverseOnSurface" })
		left = 16 + 20 + 12
	end

	local title = Creator.new("TextLabel", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, left, 0.5, props.Content and -10 or 0),
		Size = UDim2.new(1, -(left + 24), 0, 20),
		BackgroundTransparency = 1,
		Font = theme.fonts.bold,
		Text = props.Title or "",
		TextColor3 = theme.colors.inverseOnSurface,
		TextSize = theme.type.titleSmall.size,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = surface,
	}, { TextColor3 = "inverseOnSurface" })

	local content = nil
	if props.Content then
		content = Creator.new("TextLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, left, 0.5, 11),
			Size = UDim2.new(1, -(left + 24), 0, 18),
			BackgroundTransparency = 1,
			Font = theme.fonts.regular,
			Text = props.Content,
			TextColor3 = theme.colors.inverseOnSurface,
			TextSize = theme.type.bodySmall.size,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = surface,
		}, { TextColor3 = "inverseOnSurface" })
	end

	local action = nil
	if props.Action then
		action = Creator.new("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.fromOffset(96, 36),
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Text = props.Action.Title or "OK",
			Font = theme.fonts.bold,
			TextColor3 = theme.colors.inversePrimary,
			TextSize = theme.type.labelLarge.size,
			Parent = surface,
		}, { TextColor3 = "inversePrimary" })
		action.MouseButton1Click:Connect(function()
			if props.Action.Callback then
				task.spawn(props.Action.Callback)
			end
			dismiss()
		end)
	end

	local closed = false
	local function dismiss()
		if closed then
			return
		end
		closed = true
		Motion.tween(container, { Position = UDim2.new(0.5, 0, 1, 0) }, theme.motion.emphasizedAccelerate)
		Motion.tween(surface, { BackgroundTransparency = 1 }, theme.motion.emphasizedAccelerate)
		task.delay(theme.motion.emphasizedAccelerate.time, function()
			container:Destroy()
		end)
	end

	container.Position = UDim2.new(0.5, 0, 1, 24)
	Motion.tween(container, { Position = UDim2.new(0.5, 0, 1, -24) }, theme.motion.emphasizedDecelerate)
	Motion.tween(surface, { BackgroundTransparency = 0 }, theme.motion.emphasizedDecelerate)

	local duration = props.Duration or 4
	if duration > 0 then
		task.delay(duration, dismiss)
	end

	QUEUE[#QUEUE + 1] = container
	return {
		Dismiss = dismiss,
		Container = container,
	}
end

return Notification
