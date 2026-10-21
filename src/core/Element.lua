local Creator = require(script.Parent.Creator)
local Motion = require(script.Parent.Motion)
local Icons = require(script.Parent.Parent.icons.Init)

local Element = {}
Element.__index = Element

Element.Metrics = {
	padLeft = 16,
	padRight = 16,
	iconSize = 22,
	iconGap = 14,
	titleGap = 12,
	rowHeight = 52,
	rowHeightTall = 68,
	titleSize = 15,
	descSize = 12,
}

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
	return handle.window.theme.colors[key]
end

function Element.themeShape(handle, key)
	return handle.window.theme.shape[key]
end

function Element.typeOf(handle, name)
	return handle.window.theme.type[name]
end

function Element.fontFor(handle, weight)
	local fonts = handle.window.theme.fonts
	return fonts[weight] or fonts.regular
end

function Element.setLocked(handle, locked, reason)
	handle.locked = locked
	if not handle.main then
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
				Parent = handle.main,
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

function Element.setHover(handle, hovered)
	if not handle.stateLayer or handle.locked then
		return
	end
	local theme = handle.window.theme
	local target = hovered and 1 - theme.state.hover or 1
	Motion.tween(handle.stateLayer, { BackgroundTransparency = target }, theme.motion.short)
end

function Element.setPressed(handle, pressed)
	if not handle.stateLayer or handle.locked then
		return
	end
	local theme = handle.window.theme
	local target = pressed and 1 - theme.state.pressed or 1
	Motion.tween(handle.stateLayer, { BackgroundTransparency = target }, theme.motion.short)
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

function Element.reveal(handle, delay)
	local main = handle.main
	if not main or not main.Parent then
		return
	end
	local theme = handle.window.theme
	local targets = {}
	local originals = {}

	for _, child in ipairs(main:GetChildren()) do
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
