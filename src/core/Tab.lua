local Creator = require(script.Parent.Creator)
local Motion = require(script.Parent.Motion)
local Container = require(script.Parent.Container)
local Icons = require(script.Parent.Parent.icons.Init)

local Tab = {}
Tab.__index = Tab

function Tab.new(ctx)
	local props = ctx.props or {}
	local window = ctx.window
	Creator.window = window

	local self = setmetatable({
		window = window,
		props = props,
		name = props.Title or props.Name or "Tab",
		icon = props.Icon,
		__type = "Tab",
		__built = false,
		connections = {},
		selected = false,
	}, Tab)

	Container.init(self)
	self:_createSelector()
	self:_createPage()
	return self
end

function Tab:_connect(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(self.connections, connection)
	return connection
end

function Tab:_createSelector()
	local window = self.window
	local theme = window.theme
	local sidebar = window.layout == "sidebar"

	local item = Creator.new("TextButton", {
		Name = "TabItem",
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		Parent = window.navList,
	})
	self.item = item

	if sidebar then
		item.Size = UDim2.new(1, 0, 0, 42)
		item.AutomaticSize = Enum.AutomaticSize.None
	else
		item.Size = UDim2.new(0, 0, 0, 36)
		item.AutomaticSize = Enum.AutomaticSize.X
	end

	local indicator = Creator.new("Frame", {
		Name = "Indicator",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = theme.colors.secondaryContainer,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = item,
	}, { BackgroundColor3 = "secondaryContainer" })
	self.indicator = indicator

	Creator.new("UICorner", {
		CornerRadius = theme.shape.button,
		Parent = indicator,
	})

	local hover = Creator.new("Frame", {
		Name = "Hover",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = theme.colors.onSurface,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = item,
	}, { BackgroundColor3 = "onSurface" })
	self.hover = hover

	local row = Creator.new("Frame", {
		Name = "Row",
		Size = UDim2.new(1, 0, 1, 0),
		AutomaticSize = sidebar and Enum.AutomaticSize.None or Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Parent = item,
	})

	Creator.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 10),
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Parent = row,
	})

	local left = 16
	local icon = nil
	if self.icon then
		icon = Creator.new("ImageLabel", {
			Size = UDim2.fromOffset(20, 20),
			BackgroundTransparency = 1,
			Image = Icons.image(self.icon) or "",
			ImageColor3 = theme.colors.onSurfaceVariant,
			ScaleType = Enum.ScaleType.Fit,
			LayoutOrder = 0,
			Parent = row,
		}, { ImageColor3 = "onSurfaceVariant" })
		self.iconLabel = icon
		left = 16 + 20 + 10
	end

	local label = Creator.new("TextLabel", {
		Size = UDim2.new(1, -(left + 16), 1, 0),
		AutomaticSize = sidebar and Enum.AutomaticSize.None or Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Font = theme.fonts.medium,
		Text = self.name,
		TextColor3 = theme.colors.onSurfaceVariant,
		TextSize = theme.type.labelLarge.size,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		LayoutOrder = 1,
		Parent = row,
	}, { TextColor3 = "onSurfaceVariant" })
	self.label = label

	if not sidebar then
		local underline = Creator.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, 0),
			Size = UDim2.new(1, -24, 0, 3),
			BackgroundColor3 = theme.colors.primary,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Parent = item,
		}, { BackgroundColor3 = "primary" })
		self.underline = underline
		Creator.new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = underline })
	end

	local function onEnter()
		Motion.tween(hover, { BackgroundTransparency = 1 - theme.state.hover }, theme.motion.short)
	end
	local function onLeave()
		Motion.tween(hover, { BackgroundTransparency = 1 }, theme.motion.short)
	end
	item.MouseEnter:Connect(onEnter)
	item.MouseLeave:Connect(onLeave)
	item.MouseButton1Click:Connect(function()
		window:selectTab(self)
	end)

	if not sidebar then
		Creator.new("UIPadding", {
			PaddingLeft = UDim.new(0, 14),
			PaddingRight = UDim.new(0, 14),
			Parent = item,
		})
		self.padding = nil
	end
end

function Tab:_createPage()
	local window = self.window
	local page = Creator.new("ScrollingFrame", {
		Name = "Page",
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.fromScale(0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = window.theme.colors.outlineVariant,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ElasticBehavior = Enum.ElasticBehavior.Never,
		Visible = false,
		Parent = window.pages,
	})
	self.page = page

	local layout = Creator.new("UIListLayout", {
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Parent = page,
	})
	self.pageLayout = layout

	local padding = Creator.new("UIPadding", {
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 14),
		PaddingLeft = UDim.new(0, 4),
		PaddingRight = UDim.new(0, 4),
		Parent = page,
	})
	self.pagePadding = padding

	local function updateCanvas()
		local width = page.AbsoluteSize.X
		if width <= 0 then
			return
		end
		local content = layout.AbsoluteContentSize or Vector2.new(0, 0)
		local height = content.Y + padding.PaddingTop.Offset + padding.PaddingBottom.Offset
		local current = page.CanvasSize
		if current.X.Offset == width and current.Y.Offset == math.ceil(height) then
			return
		end
		page.CanvasSize = UDim2.new(0, width, 0, math.ceil(height))
	end
	self._updateCanvas = updateCanvas

	self:_connect(layout:GetPropertyChangedSignal("AbsoluteContentSize"), updateCanvas)
	self:_connect(page:GetPropertyChangedSignal("AbsoluteSize"), updateCanvas)

	self.contentFrame = page
end

function Tab:select()
	self.window:selectTab(self)
end

function Tab:reset()
	Container.reset(self)
end

function Tab:deselect()
	local theme = self.window.theme
	self.selected = false
	Motion.tween(self.indicator, { BackgroundTransparency = 1 }, theme.motion.short)
	if self.underline then
		Motion.tween(self.underline, { BackgroundTransparency = 1 }, theme.motion.short)
	end
	Motion.tween(self.label, { TextColor3 = theme.colors.onSurfaceVariant }, theme.motion.short)
	if self.iconLabel then
		Motion.tween(self.iconLabel, { ImageColor3 = theme.colors.onSurfaceVariant }, theme.motion.short)
	end
end

function Tab:_applySelected()
	local theme = self.window.theme
	self.selected = true
	if self.window.layout == "sidebar" then
		Motion.tween(self.indicator, { BackgroundTransparency = 0 }, theme.motion.short)
	elseif self.underline then
		Motion.tween(self.underline, { BackgroundTransparency = 0 }, theme.motion.short)
	end
	Motion.tween(self.label, { TextColor3 = theme.colors.onSurface }, theme.motion.short)
	if self.iconLabel then
		Motion.tween(self.iconLabel, { ImageColor3 = theme.colors.onSurface }, theme.motion.short)
	end
end

function Tab:setTitle(text)
	self.name = text
	self.label.Text = text
end

function Tab:_rebuild()
	if self.item then
		self.item:Destroy()
	end
	if self.page then
		self.page:Destroy()
	end
	self.item = nil
	self.page = nil
	self:_createSelector()
	self:_createPage()
	self.item.LayoutOrder = self._index or 1
	self.page.LayoutOrder = self._index or 1
	self:reset()
	if self.selected then
		self:flush()
		self:_applySelected()
		self.page.Visible = true
		self.page.Position = UDim2.fromScale(0, 0)
	end
end

function Tab:_destroy()
	if self.main then
		self.main:Destroy()
	end
	if self.page then
		self.page:Destroy()
	end
	if self.item then
		self.item:Destroy()
	end
end

setmetatable(Tab, { __index = Container })

return Tab
