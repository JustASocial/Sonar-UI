local Creator = require(script.Parent.Creator)
local Motion = require(script.Parent.Motion)
local Container = require(script.Parent.Container)
local Icons = require(script.Parent.Parent.icons.Init)

local Section = {}
Section.__index = Section

function Section.new(ctx)
	local props = ctx.props or {}
	local window = ctx.window
	Creator.window = window

	local self = setmetatable({
		window = window,
		container = ctx.container,
		props = props,
		expanded = props.Expanded ~= false,
		__type = "Section",
		__built = false,
		connections = {},
	}, Section)

	Container.init(self)
	return self
end

function Section:_build(parentFrame, order)
	local theme = self.window.theme
	local props = self.props

	local main = Creator.new("Frame", {
		Name = "Section",
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	})
	self.main = main
	main.Parent = parentFrame

	local header = Creator.new("TextButton", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		Parent = main,
	})
	self.header = header

	local state = Creator.new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = theme.colors.onSurface,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = header,
	}, { BackgroundColor3 = "onSurface" })
	self.state = state

	local icon = nil
	local left = 16
	if props.Icon then
		icon = Creator.new("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 16, 0.5, 0),
			Size = UDim2.fromOffset(20, 20),
			BackgroundTransparency = 1,
			Image = Icons.image(props.Icon) or "",
			ImageColor3 = theme.colors.onSurfaceVariant,
			ScaleType = Enum.ScaleType.Fit,
			Parent = header,
		}, { ImageColor3 = "onSurfaceVariant" })
		self.icon = icon
		left = 16 + 20 + 12
	end

	local title = Creator.new("TextLabel", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, left, 0.5, 0),
		Size = UDim2.new(1, -(left + 40), 1, 0),
		BackgroundTransparency = 1,
		Font = self.window.theme.fonts.bold,
		Text = props.Title or "",
		TextColor3 = theme.colors.onSurface,
		TextSize = theme.type.titleSmall.size,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = header,
	}, { TextColor3 = "onSurface" })
	self.title = title

	local chevron = Creator.new("ImageLabel", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -16, 0.5, 0),
		Size = UDim2.fromOffset(18, 18),
		BackgroundTransparency = 1,
		Image = Icons.image("chevron-down") or "",
		ImageColor3 = theme.colors.onSurfaceVariant,
		ScaleType = Enum.ScaleType.Fit,
		Parent = header,
	}, { ImageColor3 = "onSurfaceVariant" })
	self.chevron = chevron

	local content = Creator.new("Frame", {
		Name = "Content",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = main,
	})
	self.contentFrame = content

	Creator.new("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Parent = content,
	})

	Creator.new("UIPadding", {
		PaddingBottom = UDim.new(0, 6),
		Parent = content,
	})

	Creator.new("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = theme.colors.outlineVariant,
		Transparency = 0.6,
		Thickness = 1,
		Parent = content,
	}, { Color = "outlineVariant" })

	local corner = Creator.new("UICorner", {
		CornerRadius = theme.shape.element,
		Parent = content,
	})
	self.corner = corner

	self:_wire()
	if self.expanded then
		self:flush()
	end
end

function Section:_wire()
	local function toggle()
		self:setExpanded(not self.expanded)
	end
	self.header.MouseButton1Click:Connect(toggle)
	self.header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			Motion.tween(self.state, { BackgroundTransparency = 1 - self.window.theme.state.pressed }, self.window.theme.motion.short4)
		end
	end)
	self.header.InputEnded:Connect(function()
		Motion.tween(self.state, { BackgroundTransparency = 1 }, self.window.theme.motion.short4)
	end)
end

function Section:setExpanded(expanded)
	local theme = self.window.theme
	self.expanded = expanded
	self.contentFrame.Visible = expanded
	if expanded then
		self:flush()
		Motion.tween(self.chevron, { Rotation = 0 }, theme.motion.short)
	else
		Motion.tween(self.chevron, { Rotation = -90 }, theme.motion.short)
	end
	self.chevron.Rotation = expanded and 0 or -90
end

function Section:toggle()
	self:setExpanded(not self.expanded)
end

function Section:setTitle(text)
	self.title.Text = text
end

function Section:reset()
	Container.reset(self)
end

function Section:_destroy()
	if self.main then
		self.main:Destroy()
	end
end

return Section
