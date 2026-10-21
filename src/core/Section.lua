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
		Size = UDim2.new(1, 0, 0, 40),
		AutomaticSize = Enum.AutomaticSize.None,
		BackgroundTransparency = 1,
		Parent = parentFrame,
	})
	self.main = main

	local stack = Creator.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 0),
		Parent = main,
	})

	local header = Creator.new("TextButton", {
		Name = "Header",
		LayoutOrder = 1,
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

	Creator.new("UICorner", {
		CornerRadius = theme.shape.element,
		Parent = header,
	})

	local left = 16
	if props.Icon then
		local icon = Creator.new("ImageLabel", {
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
		Size = UDim2.new(1, -(left + 44), 1, 0),
		BackgroundTransparency = 1,
		Font = theme.fonts.bold,
		Text = props.Title or "",
		TextColor3 = theme.colors.onSurface,
		TextSize = theme.type.titleMedium.size,
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
		LayoutOrder = 2,
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
		PaddingBottom = UDim.new(0, 4),
		Parent = content,
	})

	Creator.new("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = theme.colors.outlineVariant,
		Transparency = 0.6,
		Thickness = 1,
		Parent = content,
	}, { Color = "outlineVariant" })

	Creator.new("UICorner", {
		CornerRadius = theme.shape.element,
		Parent = content,
	})

	self:_wire()
	self.chevron.Rotation = self.expanded and 0 or -90
	if self.expanded then
		self:flush()
	end
	task.defer(function()
		if self.main and self.main.Parent then
			self:_applyHeight(false)
		end
	end)
end

function Section:_wire()
	local theme = self.window.theme

	self.header.MouseButton1Click:Connect(function()
		self:setExpanded(not self.expanded)
	end)

	self.header.MouseEnter:Connect(function()
		Motion.tween(self.state, { BackgroundTransparency = 1 - theme.state.hover }, theme.motion.short)
	end)

	self.header.MouseLeave:Connect(function()
		Motion.tween(self.state, { BackgroundTransparency = 1 }, theme.motion.short)
	end)

	self.header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			Motion.tween(self.state, { BackgroundTransparency = 1 - theme.state.pressed }, theme.motion.short4)
		end
	end)

	self.header.InputEnded:Connect(function()
		Motion.tween(self.state, { BackgroundTransparency = 1 - theme.state.hover }, theme.motion.short4)
	end)
end

function Section:setExpanded(expanded)
	local theme = self.window.theme
	if expanded == self.expanded then
		return
	end
	self.expanded = expanded

	if expanded then
		self.contentFrame.Visible = true
		self:flush()
		task.defer(function()
			self:_applyHeight(true)
		end)
	else
		self:_applyHeight(false)
	end

	Motion.tween(self.chevron, { Rotation = expanded and 0 or -90 }, theme.motion.emphasized)
	self.chevron.Rotation = expanded and 0 or -90
end

function Section:_applyHeight(animate)
	local theme = self.window.theme
	local headerHeight = 40
	local contentHeight = self.contentFrame.AbsoluteSize.Y
	local target = self.expanded and (headerHeight + contentHeight) or headerHeight

	if not animate then
		self.main.Size = UDim2.new(1, 0, 0, target)
		if not self.expanded then
			self.contentFrame.Visible = false
		end
		return
	end

	Motion.tween(self.main, { Size = UDim2.new(1, 0, 0, target) }, theme.motion.emphasized)
	if not self.expanded then
		task.delay(theme.motion.emphasized.time, function()
			if not self.expanded then
				self.contentFrame.Visible = false
			end
		end)
	end
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

function Section:_refreshTheme()
	if not self.main then
		return
	end
	local theme = self.window.theme
	self.title.TextColor3 = theme.colors.onSurface
	if self.icon then
		self.icon.ImageColor3 = theme.colors.onSurfaceVariant
	end
	self.chevron.ImageColor3 = theme.colors.onSurfaceVariant
end

function Section:_destroy()
	if self.main then
		self.main:Destroy()
	end
end

setmetatable(Section, { __index = Container })

return Section
