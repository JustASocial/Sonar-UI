local Creator = require(script.Parent.Creator)
local Motion = require(script.Parent.Motion)
local Icons = require(script.Parent.Parent.icons.Init)

local Element = {}
Element.__index = Element

local ROW_HEIGHT = 48
local ROW_HEIGHT_WITH_DESC = 64

function Element.new(ctx)
	local props = ctx.props or {}
	Creator.window = ctx.window
	local handle = setmetatable({
		__type = ctx.typeName,
		__built = false,
		window = ctx.window,
		container = ctx.container,
		props = props,
		connections = {},
		instances = {},
		locked = false,
		flag = props.Flag,
	}, Element)
	return handle
end

function Element.track(handle, instance)
	table.insert(handle.instances, instance)
	return instance
end

function Element.connect(handle, signal, callback)
	local connection = signal:Connect(callback)
	table.insert(handle.connections, connection)
	return connection
end

function Element.themeColor(handle, key)
	local theme = handle.window.theme
	return theme.colors[key]
end

function Element.themeShape(handle, key)
	local theme = handle.window.theme
	return theme.shape[key]
end

function Element.typeOf(handle, name)
	local scale = handle.window.theme.type[name]
	return scale
end

function Element.fontFor(handle, weight)
	local fonts = handle.window.theme.fonts
	return fonts[weight] or fonts.regular
end

function Element.createRow(handle, options)
	options = options or {}
	local window = handle.window
	local theme = window.theme
	local props = handle.props

	local height = options.height
	if not height then
		height = props.Description and ROW_HEIGHT_WITH_DESC or ROW_HEIGHT
	end

	local main = Creator.new("Frame", {
		Name = handle.__type,
		Size = UDim2.new(1, 0, 0, height),
		BackgroundTransparency = 1,
		ClipsDescendants = false,
	})
	Element.track(handle, main)
	handle.main = main

	local fill = Creator.new("Frame", {
		Name = "Fill",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = theme.colors.surfaceContainerLow,
		BorderSizePixel = 0,
		Parent = main,
	}, { BackgroundColor3 = options.surface or "surfaceContainerLow", BackgroundTransparency = options.surfaceTransparency })
	Element.track(handle, fill)
	handle.fill = fill

	Creator.new("UICorner", {
		CornerRadius = options.corner or theme.shape.element,
		Parent = fill,
	})

	local stateLayer = Creator.new("Frame", {
		Name = "StateLayer",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = options.stateColor or theme.colors.onSurface,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = fill.ZIndex + 1,
		Parent = fill,
	}, { BackgroundColor3 = options.stateColor or "onSurface" })
	Element.track(handle, stateLayer)
	handle.stateLayer = stateLayer

	local stroke = Creator.new("UIStroke", {
		Transparency = options.strokeTransparency or 1,
		Thickness = 1,
		Parent = fill,
	}, { Color = options.strokeColor or "outlineVariant", Transparency = options.strokeTransparency or 1 })
	Element.track(handle, stroke)
	handle.stroke = stroke

	local left = 16
	local iconSize = options.iconSize or 24

	local icon = nil
	if options.icon then
		icon = Creator.new("ImageLabel", {
			Name = "Icon",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 16, 0.5, 0),
			Size = UDim2.fromOffset(iconSize, iconSize),
			BackgroundTransparency = 1,
			Image = Icons.image(options.icon) or "",
			ImageColor3 = options.iconColor or theme.colors.onSurfaceVariant,
			ScaleType = Enum.ScaleType.Fit,
		}, { ImageColor3 = options.iconColor or "onSurfaceVariant" })
		Element.track(handle, icon)
		handle.icon = icon
		left = 16 + iconSize + 12
	end

	local controlWidth = options.controlWidth or 0
	local titleWidth = UDim2.new(1, -(left + 16 + controlWidth), 0, 0)

	local title = Creator.new("TextLabel", {
		Name = "Title",
		Position = UDim2.new(0, left, 0, props.Description and 12 or 0),
		AnchorPoint = Vector2.new(0, 0),
		Size = titleWidth,
		BackgroundTransparency = 1,
		Font = Element.fontFor(handle, "bold"),
		Text = options.title or props.Title or "",
		TextColor3 = theme.colors.onSurface,
		TextSize = Element.typeOf(handle, "titleMedium").size,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = props.Description and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextWrapped = false,
	}, { TextColor3 = "onSurface" })
	Element.track(handle, title)
	handle.title = title

	local desc = nil
	if props.Description then
		desc = Creator.new("TextLabel", {
			Name = "Description",
			Position = UDim2.new(0, left, 0, 34),
			Size = titleWidth,
			BackgroundTransparency = 1,
			Font = Element.fontFor(handle, "regular"),
			Text = props.Description,
			TextColor3 = theme.colors.onSurfaceVariant,
			TextSize = Element.typeOf(handle, "bodySmall").size,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextWrapped = false,
		}, { TextColor3 = "onSurfaceVariant" })
		Element.track(handle, desc)
		handle.desc = desc
	end

	local content = Creator.new("Frame", {
		Name = "Content",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -16, 0.5, 0),
		Size = UDim2.new(0, controlWidth, 1, 0),
		BackgroundTransparency = 1,
	})
	Element.track(handle, content)
	handle.content = content

	if options.locked or props.Locked then
		Element.setLocked(handle, true, props.LockedTitle)
	end

	return main, fill, stateLayer, title, desc, content
end

function Element.setHover(handle, hovered)
	if not handle.stateLayer or handle.locked then
		return
	end
	local theme = handle.window.theme
	local target = hovered and 1 - theme.state.hover or 1
	Motion.tween(handle.stateLayer, { BackgroundTransparency = target }, theme.motion.short4)
end

function Element.reveal(handle, delay)
	local main = handle.main
	if not main or not main.Parent then
		return
	end
	local theme = handle.window.theme
	local targets = {}
	local originals = {}

	for _, child in ipairs(main:GetDescendants()) do
		if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("ImageLabel") then
			table.insert(targets, child)
			if child:IsA("ImageLabel") then
				originals[child] = child.ImageTransparency
			else
				originals[child] = child.TextTransparency
			end
		end
	end

	local originalTransparency = main.BackgroundTransparency
	main.BackgroundTransparency = 1
	for _, target in ipairs(targets) do
		if target:IsA("ImageLabel") then
			target.ImageTransparency = 1
		else
			target.TextTransparency = 1
		end
	end

	task.delay(delay or 0, function()
		if not main.Parent then
			return
		end
		Motion.tween(main, {
			BackgroundTransparency = originalTransparency,
		}, theme.motion.emphasizedDecelerate)
		for _, target in ipairs(targets) do
			if target:IsA("ImageLabel") then
				Motion.tween(target, { ImageTransparency = originals[target] }, theme.motion.emphasizedDecelerate)
			else
				Motion.tween(target, { TextTransparency = originals[target] }, theme.motion.emphasizedDecelerate)
			end
		end
	end)
end

function Element.setPressed(handle, pressed)
	if not handle.stateLayer or handle.locked then
		return	end
	local theme = handle.window.theme
	local target = pressed and 1 - theme.state.pressed or 1
	Motion.tween(handle.stateLayer, { BackgroundTransparency = target }, theme.motion.short4)
end

function Element.wireHover(handle, target)
	target = target or handle.main
	if not target then
		return
	end
	Element.connect(handle, target.MouseEnter, function()
		if handle.locked then
			return
		end
		Element.setHover(handle, true)
	end)
	Element.connect(handle, target.MouseLeave, function()
		Element.setPressed(handle, false)
		Element.setHover(handle, false)
	end)
	Element.connect(handle, target.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			Element.setPressed(handle, true)
		end
	end)
	Element.connect(handle, target.InputEnded, function()
		Element.setPressed(handle, false)
	end)
end

function Element.setLocked(handle, locked, reason)
	handle.locked = locked
	if not handle.fill then
		return
	end
	if locked then
		if not handle.lockFrame then
			local overlay = Creator.new("Frame", {
				Name = "Lock",
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = handle.window.theme.colors.surfaceContainerHighest,
				BackgroundTransparency = 0.35,
				BorderSizePixel = 0,
				ZIndex = 50,
				Parent = handle.fill,
			}, { BackgroundColor3 = "surfaceContainerHighest" })
			Creator.new("UICorner", { CornerRadius = handle.window.theme.shape.element, Parent = overlay })
			local icon = Creator.new("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(20, 20),
				BackgroundTransparency = 1,
				Image = Icons.image("lock") or "",
				ImageColor3 = handle.window.theme.colors.onSurfaceVariant,
			}, { ImageColor3 = "onSurfaceVariant" })
			icon.Parent = overlay
			handle.lockFrame = overlay
		end
		handle.lockFrame.Visible = true
		if reason then
			handle.lockFrame.Name = "Lock:" .. tostring(reason)
		end
	else
		if handle.lockFrame then
			handle.lockFrame.Visible = false
		end
	end
end

function Element.destroy(handle)
	for _, connection in ipairs(handle.connections) do
		pcall(function()
			connection:Disconnect()
		end)
	end
	handle.connections = {}
	if handle.main then
		for _, instance in ipairs(handle.instances) do
			if instance ~= handle.main and instance.Parent ~= nil then
				instance:Destroy()
			end
		end
		Creator.prune({ handle.main })
		handle.main:Destroy()
	end
end

function Element.refreshTheme(handle)
	if handle._refreshTheme then
		handle:_refreshTheme()
	end
end

return Element
