local Creator = require(script.Parent.Creator)
local Motion = require(script.Parent.Motion)
local Theme = require(script.Parent.Parent.theme.Init)
local Variables = require(script.Parent.Variables)
local Locale = require(script.Parent.Parent.locale.Init)
local Config = require(script.Parent.Parent.config.Init)
local Icons = require(script.Parent.Parent.icons.Init)
local Tab = require(script.Parent.Tab)
local Notification = require(script.Parent.Notification)
local Popup = require(script.Parent.Popup)

local Window = {}
Window.__index = Window

local TOPBAR_HEIGHT = 64
local RAIL_WIDTH = 216
local STRIP_HEIGHT = 48

function Window.new(props)
	props = props or {}

	local themeSpec = {
		name = props.Theme or "Material",
		mode = props.Mode or "dark",
		seed = props.Accent,
	}
	if type(props.Theme) == "table" then
		for key, value in pairs(props.Theme) do
			themeSpec[key] = value
		end
	end

	local self = setmetatable({
		props = props,
		title = props.Title or "Sonar",
		subtitle = props.Subtitle,
		icon = props.Icon,
		theme = Theme.build(themeSpec),
		layout = props.Layout or "sidebar",
		tabs = {},
		selectedTab = nil,
		flags = {},
		connections = {},
		visible = false,
		animating = false,
		unloaded = false,
		size = props.Size or UDim2.fromOffset(780, 540),
		minSize = props.MinSize or UDim2.fromOffset(520, 360),
	}, Window)

	Creator.window = self

	self.configManager = Config.Manager.new(self)
	self.locale = Locale.new(props.Locale or {})
	self.locale:onChange(function()
		self:_refreshLocale()
	end)

	self:_buildScreen()
	self:_buildSurface()
	self:_buildTopbar()
	self:_buildNavigation()
	self:_buildPages()
	self:_enableDrag()

	self.config = self.configManager:create(props.ConfigName or "config", props.AutoSave ~= false)

	if props.AutoSave ~= false then
		task.defer(function()
			if self.unloaded then
				return
			end
			self.config:load()
			self:_restoreSettings()
		end)
	end

	return self
end

function Window:_storeSettings()
	local seed = self.theme.seed
	self.config.custom.theme = {
		name = self.theme.name,
		mode = self.theme.mode,
		seed = { r = seed.R, g = seed.G, b = seed.B },
	}
	self.config.custom.language = self.locale.current
	self.config.custom.layout = self.layout
end

function Window:_restoreSettings()
	local custom = self.config.custom
	local theme = custom.theme
	if type(theme) == "table" then
		local seed = theme.seed
		self:setTheme({
			name = theme.name or self.theme.name,
			mode = theme.mode or self.theme.mode,
			seed = type(seed) == "table" and Color3.new(seed.r, seed.g, seed.b) or self.theme.seed,
		})
	end
	if type(custom.language) == "string" and custom.language ~= self.locale.current then
		self:setLanguage(custom.language)
	end
	if type(custom.layout) == "string" and custom.layout ~= self.layout then
		self:setLayout(custom.layout)
	end
end

function Window:_connect(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(self.connections, connection)
	return connection
end

function Window:_enableDrag()
	local dragging = false
	local offset = Vector2.new(0, 0)

	self.topbar.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		if self.minimised then
			return
		end
		local actions = self.actions
		if actions and actions.AbsoluteSize.X > 0 then
			local rect = actions.AbsolutePosition
			if input.Position.X >= rect.X and input.Position.X <= rect.X + actions.AbsoluteSize.X then
				return
			end
		end
		dragging = true
		local root = self.root
		offset = Vector2.new(
			input.Position.X - root.AbsolutePosition.X,
			input.Position.Y - root.AbsolutePosition.Y
		)
	end)

	self:_connect(Variables.services.UserInputService.InputChanged, function(input)
		if not dragging then
			return
		end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local root = self.root
		local size = root.AbsoluteSize
		local x = input.Position.X - offset.X + size.X / 2
		local y = input.Position.Y - offset.Y + size.Y / 2
		root.Position = UDim2.fromOffset(x, y)
	end)

	self:_connect(Variables.services.UserInputService.InputEnded, function()
		dragging = false
	end)
end

function Window:_buildScreen()
	local screen = Instance.new("ScreenGui")
	screen.Name = "Sonar"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.DisplayOrder = Variables.displayOrder
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screen.Enabled = true
	screen.Parent = Variables.getContainer()
	self.screen = screen

	self.overlay = Instance.new("ScreenGui")
	self.overlay.Name = "SonarOverlay"
	self.overlay.ResetOnSpawn = false
	self.overlay.IgnoreGuiInset = true
	self.overlay.DisplayOrder = Variables.displayOrder + 1
	self.overlay.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	self.overlay.Parent = Variables.getContainer()
	self.overlayGui = self.overlay
end

function Window:_buildSurface()
	local theme = self.theme

	local root = Creator.new("Frame", {
		Name = "Root",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = self.size,
		BackgroundTransparency = 1,
	})
	self.root = root
	root.Parent = self.screen

	local surface = Creator.new("Frame", {
		Name = "Surface",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = theme.colors.surface,
		BorderSizePixel = 0,
	}, { BackgroundColor3 = "surface" })
	self.surface = surface
	surface.Parent = root

	Creator.new("UICorner", {
		CornerRadius = theme.shape.window,
		Parent = surface,
	})

	local stroke = Creator.new("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = theme.colors.outlineVariant,
		Transparency = 0.4,
		Thickness = 1,
		Parent = surface,
	}, { Color = "outlineVariant" })
	self.stroke = stroke

	local divider = Creator.new("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 0, TOPBAR_HEIGHT - 1),
		BackgroundColor3 = theme.colors.outlineVariant,
		BackgroundTransparency = 0.7,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = surface,
	}, { BackgroundColor3 = "outlineVariant" })
	self.topDivider = divider
end

function Window:_buildTopbar()
	local theme = self.theme
	local topbar = Creator.new("Frame", {
		Name = "Topbar",
		Size = UDim2.new(1, 0, 0, TOPBAR_HEIGHT),
		BackgroundTransparency = 1,
		ZIndex = 3,
		Parent = self.surface,
	})
	self.topbar = topbar

	local left = 16
	if self.icon then
		local icon = Creator.new("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 16, 0.5, 0),
			Size = UDim2.fromOffset(28, 28),
			BackgroundTransparency = 1,
			Image = Icons.image(self.icon) or "",
			ImageColor3 = theme.colors.onSurface,
			ScaleType = Enum.ScaleType.Fit,
			Parent = topbar,
		}, { ImageColor3 = "onSurface" })
		self.iconLabel = icon
		left = 16 + 28 + 14
	end

	local title = Creator.new("TextLabel", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, left, 0.5, self.subtitle and -10 or 0),
		Size = UDim2.new(1, -(left + 140), 0, 24),
		BackgroundTransparency = 1,
		Font = theme.fonts.bold,
		Text = self.title,
		TextColor3 = theme.colors.onSurface,
		TextSize = theme.type.titleLarge.size,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 4,
		Parent = topbar,
	}, { TextColor3 = "onSurface" })
	self.titleLabel = title

	if self.subtitle then
		local subtitle = Creator.new("TextLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, left, 0.5, 11),
			Size = UDim2.new(1, -(left + 140), 0, 18),
			BackgroundTransparency = 1,
			Font = theme.fonts.regular,
			Text = self.subtitle,
			TextColor3 = theme.colors.onSurfaceVariant,
			TextSize = theme.type.bodySmall.size,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 4,
			Parent = topbar,
		}, { TextColor3 = "onSurfaceVariant" })
		self.subtitleLabel = subtitle
	end

	local actions = Creator.new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.new(0, 88, 0, 40),
		BackgroundTransparency = 1,
		ZIndex = 4,
		Parent = topbar,
	})
	self.actions = actions

	Creator.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = actions,
	})

	local minimiseButton, minimiseIcon = self:_createAction("minimize", "minus", function()
		self:toggleMinimise()
	end)
	self.minimiseButton = minimiseButton
	self.minimiseIcon = minimiseIcon
	self:_createAction("close", "x", function()
		self:close()
	end)
end

function Window:_createAction(name, iconName, callback)
	local theme = self.theme
	local button = Creator.new("TextButton", {
		Name = name,
		Size = UDim2.fromOffset(40, 40),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = name == "minimize" and 1 or 2,
		Parent = self.actions,
	})
	Creator.new("UICorner", {
		CornerRadius = theme.shape.button,
		Parent = button,
	})
	local hover = Creator.new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = theme.colors.onSurface,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = button,
	}, { BackgroundColor3 = "onSurface" })
	local icon = Creator.new("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(18, 18),
		BackgroundTransparency = 1,
		Image = Icons.image(iconName) or "",
		ImageColor3 = theme.colors.onSurfaceVariant,
		ScaleType = Enum.ScaleType.Fit,
		Parent = button,
	}, { ImageColor3 = "onSurfaceVariant" })
	button.MouseEnter:Connect(function()
		Motion.tween(hover, { BackgroundTransparency = 1 - theme.state.hover }, theme.motion.short4)
		Motion.tween(icon, { ImageColor3 = theme.colors.onSurface }, theme.motion.short4)
	end)
	button.MouseLeave:Connect(function()
		Motion.tween(hover, { BackgroundTransparency = 1 }, theme.motion.short4)
		Motion.tween(icon, { ImageColor3 = theme.colors.onSurfaceVariant }, theme.motion.short4)
	end)
	button.MouseButton1Click:Connect(callback)
	return button, icon
end

function Window:_buildNavigation()
	local theme = self.theme
	local sidebar = self.layout == "sidebar"

	local nav = Creator.new("Frame", {
		Name = "Navigation",
		BackgroundTransparency = 1,
		Parent = self.surface,
	})
	self.nav = nav

	local list = Creator.new("ScrollingFrame", {
		Name = "NavList",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollingDirection = sidebar and Enum.ScrollingDirection.Y or Enum.ScrollingDirection.X,
		ElasticBehavior = Enum.ElasticBehavior.Never,
		Parent = nav,
	})
	self.navList = list

	local navLayout = Creator.new("UIListLayout", {
		FillDirection = sidebar and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, sidebar and 4 or 6),
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		Parent = list,
	})
	self.navLayout = navLayout

	local navPadding = 0
	local function updateNavCanvas()
		local content = navLayout.AbsoluteContentSize or Vector2.new(0, 0)
		local width = list.AbsoluteSize.X
		local height = list.AbsoluteSize.Y
		if sidebar then
			if width <= 0 then
				return
			end
			local target = math.ceil(content.Y + navPadding)
			if list.CanvasSize.Y.Offset == target then
				return
			end
			list.CanvasSize = UDim2.new(0, width, 0, target)
		else
			if height <= 0 then
				return
			end
			local target = math.ceil(content.X)
			if list.CanvasSize.X.Offset == target then
				return
			end
			list.CanvasSize = UDim2.new(0, target, 0, height)
		end
	end
	self:_connect(navLayout:GetPropertyChangedSignal("AbsoluteContentSize"), updateNavCanvas)
	self:_connect(list:GetPropertyChangedSignal("AbsoluteSize"), updateNavCanvas)
	self._updateNavCanvas = updateNavCanvas

	if sidebar then
		nav.Size = UDim2.new(0, RAIL_WIDTH, 1, -TOPBAR_HEIGHT)
		nav.Position = UDim2.new(0, 0, 0, TOPBAR_HEIGHT)
		list.Size = UDim2.new(1, 0, 1, 0)
		Creator.new("UIPadding", {
			PaddingTop = UDim.new(0, 10),
			PaddingBottom = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
			Parent = list,
		})
		navPadding = 20
		local divider = Creator.new("Frame", {
			Size = UDim2.new(0, 1, 1, -28),
			Position = UDim2.new(1, 0, 0, 0),
			BackgroundColor3 = theme.colors.outlineVariant,
			BackgroundTransparency = 0.7,
			BorderSizePixel = 0,
			Parent = nav,
		}, { BackgroundColor3 = "outlineVariant" })
		self.navDivider = divider
	else
		nav.Size = UDim2.new(1, 0, 0, STRIP_HEIGHT)
		nav.Position = UDim2.new(0, 0, 0, TOPBAR_HEIGHT)
		list.Size = UDim2.new(1, 0, 1, 0)
		Creator.new("UIPadding", {
			PaddingTop = UDim.new(0, 7),
			PaddingBottom = UDim.new(0, 7),
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
			Parent = list,
		})
		local divider = Creator.new("Frame", {
			Size = UDim2.new(1, 0, 0, 1),
			Position = UDim2.new(0, 0, 1, 0),
			BackgroundColor3 = theme.colors.outlineVariant,
			BackgroundTransparency = 0.7,
			BorderSizePixel = 0,
			Parent = nav,
		}, { BackgroundColor3 = "outlineVariant" })
		self.navDivider = divider
	end
end

function Window:_buildPages()
	local sidebar = self.layout == "sidebar"
	local inset = 8
	local pages = Creator.new("Frame", {
		Name = "Pages",
		BackgroundColor3 = self.theme.colors.surfaceContainer,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = self.surface,
	}, { BackgroundColor3 = "surfaceContainer" })
	self.pages = pages

	Creator.new("UICorner", {
		CornerRadius = self.theme.shape.card,
		Parent = pages,
	})

	Creator.new("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = self.theme.colors.outlineVariant,
		Transparency = 0.6,
		Thickness = 1,
		Parent = pages,
	}, { Color = "outlineVariant" })

	if sidebar then
		pages.Size = UDim2.new(1, -(RAIL_WIDTH + inset * 2), 1, -(TOPBAR_HEIGHT + inset * 2))
		pages.Position = UDim2.new(0, RAIL_WIDTH + inset, 0, TOPBAR_HEIGHT + inset)
	else
		pages.Size = UDim2.new(1, -(inset * 2), 1, -(TOPBAR_HEIGHT + STRIP_HEIGHT + inset * 2))
		pages.Position = UDim2.new(0, inset, 0, TOPBAR_HEIGHT + STRIP_HEIGHT + inset)
	end

	self.pageLayout = nil
end

function Window:createTab(props)
	props = props or {}
	local tab = Tab.new({ window = self, props = props })
	table.insert(self.tabs, tab)
	tab._index = #self.tabs
	tab.item.LayoutOrder = tab._index
	tab.page.LayoutOrder = tab._index
	if self._updateNavCanvas then
		self._updateNavCanvas()
	end
	if not self.selectedTab then
		self:selectTab(tab, true)
	end
	return tab
end

function Window:selectTab(tab, instant)
	if self.selectedTab == tab then
		return
	end
	local previous = self.selectedTab
	if previous then
		previous:deselect()
	end
	self.selectedTab = tab
	tab.selected = true
	tab:_applySelected()
	tab:flush()
	self:_swapPages(previous, tab, instant)
end

function Window:_swapPages(previous, tab, instant)
	local theme = self.theme
	local vertical = self.layout == "sidebar"
	local rest = UDim2.fromScale(0, 0)
	local enter = vertical and UDim2.new(0, 1, 0, 0) or UDim2.new(1, 0, 0, 0)

	if previous and previous ~= tab and previous.page then
		previous.page.Visible = false
		previous.page.Position = rest
	end

	if not tab.page then
		return
	end

	tab.page.Visible = true
	if instant then
		tab.page.Position = rest
	else
		tab.page.Position = enter
		Motion.tween(tab.page, { Position = rest }, theme.motion.short)
	end
end

function Window:setLayout(layout)
	layout = layout or "sidebar"
	if layout == self.layout or (layout ~= "sidebar" and layout ~= "top") then
		return
	end
	self.layout = layout

	if self.nav then
		self.nav:Destroy()
	end
	if self.pages then
		self.pages:Destroy()
	end

	self:_buildNavigation()
	self:_buildPages()

	local current = self.selectedTab
	for _, tab in ipairs(self.tabs) do
		tab:_rebuild()
	end

	self.selectedTab = nil
	if current then
		self:selectTab(current, true)
	end
	self:_storeSettings()
	self:_persist(self)
end

function Window:navigate(name)
	for _, tab in ipairs(self.tabs) do
		if tab.name == name then
			self:selectTab(tab)
			return true
		end
	end
	return false
end

function Window:setTheme(spec)
	local themeSpec = {
		name = self.theme.name,
		mode = self.theme.mode,
		seed = self.theme.seed,
	}
	if type(spec) == "string" then
		themeSpec.name = spec
	elseif type(spec) == "table" then
		for key, value in pairs(spec) do
			themeSpec[key] = value
		end
		themeSpec.name = themeSpec.name or self.theme.name
		themeSpec.mode = themeSpec.mode or self.theme.mode
		themeSpec.seed = themeSpec.seed or self.theme.seed
	end

	self.theme = Theme.build(themeSpec)
	local previousSurface = self.surface.BackgroundColor3
	Creator.applyTheme(self.theme, false)
	local nextSurface = self.surface.BackgroundColor3
	self.surface.BackgroundColor3 = previousSurface
	Motion.tween(self.surface, { BackgroundColor3 = nextSurface }, self.theme.motion.emphasized)
	if self.selectedTab then
		self.selectedTab:_applySelected()
	end
	self:_refreshElementThemes()
	self:_storeSettings()
	self:_persist(self)
end

function Window:setAccent(color)
	self:setTheme({ seed = color })
end

function Window:_refreshElementThemes()
	for _, tab in ipairs(self.tabs) do
		for _, child in ipairs(tab.children) do
			if child._refreshTheme then
				child:_refreshTheme()
			end
		end
	end
end

function Window:_refreshLocale()
	for _, tab in ipairs(self.tabs) do
		for _, child in ipairs(tab.children) do
			if child._localeRefresh then
				child:_localeRefresh()
			end
		end
	end
end

function Window:setLanguage(language)
	self.locale:setLanguage(language)
	self:_storeSettings()
	self:_persist(self)
end

function Window:show()
	if self.visible or self.unloaded then
		return
	end
	self.visible = true
	self.root.Visible = true
	self.animating = true
	local target = self.size
	local shrunk = UDim2.new(
		target.X.Scale,
		target.X.Offset,
		target.Y.Scale,
		target.Y.Offset
	)
	local from = UDim2.new(target.X.Scale * 0.96, target.X.Offset, target.Y.Scale * 0.96, target.Y.Offset)
	self.root.Size = from
	Motion.tween(self.root, { Size = shrunk }, self.theme.motion.emphasizedDecelerate)
	Motion.tween(self.surface, { BackgroundTransparency = 0 }, self.theme.motion.emphasizedDecelerate)
	task.delay(self.theme.motion.emphasizedDecelerate.time, function()
		self.animating = false
	end)
end

function Window:hide()
	if not self.visible or self.unloaded then
		return
	end
	self.visible = false
	self.animating = true
	local target = self.size
	Motion.tween(self.root, {
		Size = UDim2.new(target.X.Scale * 0.96, target.X.Offset, target.Y.Scale * 0.96, target.Y.Offset),
	}, self.theme.motion.emphasizedAccelerate)
	Motion.tween(self.surface, { BackgroundTransparency = 1 }, self.theme.motion.emphasizedAccelerate)
	task.delay(self.theme.motion.emphasizedAccelerate.time, function()
		self.animating = false
		self.root.Visible = false
	end)
end

function Window:toggle()
	if self.visible then
		self:hide()
	else
		self:show()
	end
end

function Window:toggleMinimise()
	local theme = self.theme
	if not self.minimised then
		self.minimised = true
		self._restoreSize = self.root.Size
		self._restorePosition = self.root.Position

		self.nav.Visible = false
		self.pages.Visible = false
		if self.topDivider then
			self.topDivider.Visible = false
		end
		if self.navDivider then
			self.navDivider.Visible = false
		end
		if self.subtitleLabel then
			self.subtitleLabel.Visible = false
		end
		self.minimiseIcon.Image = Icons.image("chevron-up") or ""

		local screen = self.screen.AbsoluteSize
		local width = math.min(320, math.max(200, screen.X - 40))
		Motion.tween(self.root, {
			Size = UDim2.fromOffset(width, 52),
			Position = UDim2.fromOffset(screen.X / 2, 44),
		}, theme.motion.emphasizedDecelerate)
	else
		self.minimised = false
		self.nav.Visible = true
		self.pages.Visible = true
		if self.topDivider then
			self.topDivider.Visible = true
		end
		if self.navDivider then
			self.navDivider.Visible = true
		end
		if self.subtitleLabel then
			self.subtitleLabel.Visible = true
		end
		self.minimiseIcon.Image = Icons.image("minus") or ""
		Motion.tween(self.root, {
			Size = self._restoreSize or self.size,
			Position = self._restorePosition or UDim2.fromScale(0.5, 0.5),
		}, theme.motion.emphasizedDecelerate)
	end
end

function Window:notify(props)
	return Notification.create(self, props)
end

function Window:popup(props)
	return Popup.create(self, props)
end

function Window:saveConfig()
	return self.config:save()
end

function Window:_persist(element)
	if element ~= self and not element.flag then
		return
	end
	if self.props.AutoSave == false then
		return
	end
	if self._savePending then
		return
	end
	self._savePending = true
	task.delay(0.6, function()
		self._savePending = false
		if self.unloaded or not self.config then
			return
		end
		task.spawn(function()
			self.config:save()
		end)
	end)
end

function Window:loadConfig()
	return self.config:load()
end

function Window:listConfigs()
	return self.configManager:list()
end

function Window:deleteConfig(name)
	return self.configManager:delete(name)
end

function Window:close()
	if self.unloaded or self.closing then
		return
	end
	self.closing = true
	self.animating = true
	local theme = self.theme
	local target = self.root.Size
	Motion.tween(self.surface, { BackgroundTransparency = 1 }, theme.motion.emphasizedAccelerate)
	Motion.tween(self.root, {
		Size = UDim2.new(target.X.Scale * 0.94, target.X.Offset, target.Y.Scale * 0.94, target.Y.Offset),
	}, theme.motion.emphasizedAccelerate)
	task.delay(theme.motion.emphasizedAccelerate.time, function()
		self:unload()
	end)
end

function Window:unload()
	if self.unloaded then
		return
	end
	self.unloaded = true
	for _, connection in ipairs(self.connections) do
		pcall(function()
			connection:Disconnect()
		end)
	end
	self.connections = {}
	if self.root then
		self.root:Destroy()
	end
	if self.screen then
		self.screen:Destroy()
	end
	if self.overlay then
		self.overlay:Destroy()
	end
	Creator.destroyAll()
end

return Window
