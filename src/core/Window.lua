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

	self.config = self.configManager:create(props.ConfigName or "config", props.AutoSave ~= false)

	return self
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

	local shadow = Creator.new("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = Color3.new(0, 0, 0),
		Transparency = 0.55,
		Thickness = 14,
		Parent = root,
	})
	shadow.Name = "Shadow"
	self.shadow = shadow

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
		Position = UDim2.new(1, -8, 0.5, 0),
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

	self:_createAction("minimize", "minus", function()
		self:toggleMinimise()
	end)
	self:_createAction("close", "x", function()
		self:hide()
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
	return button
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
		AutomaticCanvasSize = sidebar and Enum.AutomaticSize.Y or Enum.AutomaticSize.X,
		ScrollingDirection = sidebar and Enum.ScrollingDirection.Y or Enum.ScrollingDirection.X,
		ElasticBehavior = Enum.ElasticBehavior.Never,
		Parent = nav,
	})
	self.navList = list

	Creator.new("UIListLayout", {
		FillDirection = sidebar and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, sidebar and 4 or 6),
		HorizontalAlignment = sidebar and Enum.HorizontalAlignment.Left or Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		Parent = list,
	})

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
		local divider = Creator.new("Frame", {
			Size = UDim2.new(0, 1, 1, 0),
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
	local pages = Creator.new("Frame", {
		Name = "Pages",
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = self.surface,
	})
	self.pages = pages

	if sidebar then
		pages.Size = UDim2.new(1, -RAIL_WIDTH, 1, -TOPBAR_HEIGHT)
		pages.Position = UDim2.new(0, RAIL_WIDTH, 0, TOPBAR_HEIGHT)
	else
		pages.Size = UDim2.new(1, 0, 1, -(TOPBAR_HEIGHT + STRIP_HEIGHT))
		pages.Position = UDim2.new(0, 0, 0, TOPBAR_HEIGHT + STRIP_HEIGHT)
	end

	self.pageLayout = Creator.new("UIPageLayout", {
		FillDirection = sidebar and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		ScrollWheelInputEnabled = false,
		GamepadInputEnabled = false,
		TouchInputEnabled = false,
		EasingStyle = Enum.EasingStyle.Quint,
		TweenTime = 0.32,
		Parent = pages,
	})
end

function Window:createTab(props)
	props = props or {}
	local tab = Tab.new({ window = self, props = props })
	table.insert(self.tabs, tab)
	tab.item.LayoutOrder = #self.tabs
	tab.page.LayoutOrder = #self.tabs
	if not self.selectedTab then
		self:selectTab(tab, true)
	end
	return tab
end

function Window:selectTab(tab, instant)
	if self.selectedTab == tab then
		return
	end
	if self.selectedTab then
		self.selectedTab:deselect()
	end
	self.selectedTab = tab
	tab.selected = true
	tab:_applySelected()
	tab:flush()
	if instant then
		local tweenTime = self.pageLayout.TweenTime
		self.pageLayout.TweenTime = 0
		self.pageLayout:JumpToPage(tab.page)
		self.pageLayout.TweenTime = tweenTime
	else
		self.pageLayout:JumpToPage(tab.page)
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
	Creator.applyTheme(self.theme, true)
	if self.selectedTab then
		self.selectedTab:_applySelected()
	end
	self:_refreshElementThemes()
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
	self.minimised = not self.minimised
	local target = self.size
	if self.minimised then
		Motion.tween(self.root, { Size = UDim2.new(target.X.Scale, target.X.Offset, 0, TOPBAR_HEIGHT) }, self.theme.motion.short)
	else
		Motion.tween(self.root, { Size = target }, self.theme.motion.short)
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
	if not element.flag then
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
