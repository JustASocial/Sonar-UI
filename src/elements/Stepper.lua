local Element = require(script.Parent.Parent.core.Element)
local Creator = require(script.Parent.Parent.core.Creator)
local Motion = require(script.Parent.Parent.core.Motion)
local Icons = require(script.Parent.Parent.icons.Init)

local Stepper = {}

local CIRCLE = 28
local GAP = 12

function Stepper.new(ctx)
	local props = ctx.props or {}
	local handle = Element.new({
		typeName = "Stepper",
		window = ctx.window,
		container = ctx.container,
		props = props,
	})
	handle.steps = props.Steps or {}
	handle.value = props.Value or 1

	function handle:_build(parentFrame, order)
		local window = self.window
		local theme = window.theme
		Creator.window = window

		local main = Creator.new("Frame", {
			Name = "Stepper",
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Parent = parentFrame,
		})
		self.main = main

		Creator.new("UIListLayout", {
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			Parent = main,
		})

		if props.Title then
			local title = Creator.new("TextLabel", {
				Size = UDim2.new(1, 0, 0, 20),
				BackgroundTransparency = 1,
				Font = theme.fonts.bold,
				Text = props.Title,
				TextColor3 = theme.colors.onSurface,
				TextSize = theme.type.titleMedium.size,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = main,
			}, { TextColor3 = "onSurface" })
			title.LayoutOrder = 1
			self.title = title
		end

		local scroller = Creator.new("ScrollingFrame", {
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = theme.colors.outlineVariant,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ElasticBehavior = Enum.ElasticBehavior.Never,
			Parent = main,
		})
		scroller.LayoutOrder = 2
		self.scroller = scroller

		local inner = Creator.new("Frame", {
			Size = UDim2.new(0, 0, 0, CIRCLE),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			Parent = scroller,
		})
		self.inner = inner

		self.items = {}
		for index, step in ipairs(self.steps) do
			self:_buildStep(step, index)
		end

		self:_render()
	end

	function handle:_buildStep(step, index)
		local theme = self.window.theme

		local holder = Creator.new("Frame", {
			Size = UDim2.fromOffset(CIRCLE, CIRCLE),
			BackgroundTransparency = 1,
			LayoutOrder = index,
			Parent = self.inner,
		})

		local circle = Creator.new("Frame", {
			Size = UDim2.fromOffset(CIRCLE, CIRCLE),
			BackgroundColor3 = theme.colors.surface,
			BorderSizePixel = 0,
			Parent = holder,
		}, { BackgroundColor3 = "surface" })
		Creator.new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = circle })

		local stroke = Creator.new("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = theme.colors.outline,
			Transparency = 0,
			Thickness = 2,
			Parent = circle,
		}, { Color = "outline" })
		self.stroke = stroke

		local label = Creator.new("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Font = theme.fonts.bold,
			Text = tostring(index),
			TextColor3 = theme.colors.onSurfaceVariant,
			TextSize = theme.type.labelLarge.size,
			Parent = circle,
		}, { TextColor3 = "onSurfaceVariant" })

		local icon = nil
		if type(step) == "table" and step.Icon then
			icon = Creator.new("ImageLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Image = Icons.image(step.Icon) or "",
				ImageColor3 = theme.colors.onPrimary,
				ScaleType = Enum.ScaleType.Fit,
				Visible = false,
				Parent = circle,
			}, { ImageColor3 = "onPrimary" })
		end

		local clickable = Creator.new("TextButton", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Text = "",
			Parent = circle,
		})

		Element.connect(self, clickable.MouseButton1Click, function()
			if self.locked or props.Clickable == false then
				return
			end
			self:Set(index, true)
			if props.Callback then
				task.spawn(props.Callback, index)
			end
		end)

		local connector = nil
		if index < #self.steps then
			connector = Creator.new("Frame", {
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.fromOffset(GAP, 2),
				BackgroundColor3 = theme.colors.outlineVariant,
				BorderSizePixel = 0,
				Parent = holder,
			}, { BackgroundColor3 = "outlineVariant" })
			Creator.new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = connector })
		end

		local caption = nil
		if type(step) == "table" and (step.Title or step.Description) then
			caption = Creator.new("TextLabel", {
				Position = UDim2.new(0.5, 0, 1, 6),
				Size = UDim2.new(1, 0, 0, 34),
				BackgroundTransparency = 1,
				Font = theme.fonts.bold,
				Text = step.Title or "",
				TextColor3 = theme.colors.onSurface,
				TextSize = theme.type.labelSmall.size,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextWrapped = true,
				Parent = holder,
			}, { TextColor3 = "onSurface" })
		end

		self.items[index] = {
			holder = holder,
			circle = circle,
			stroke = stroke,
			label = label,
			icon = icon,
			connector = connector,
			caption = caption,
			click = clickable,
		}
	end

	function handle:_render(animate)
		if not self.main then
			return
		end
		local theme = self.window.theme
		local token = animate and theme.motion.standard or theme.motion.short4

		for index, data in ipairs(self.items) do
			local completed = index < self.value
			local current = index == self.value
			local fill = completed and theme.colors.primary or (current and theme.colors.primaryContainer or theme.colors.surface)
			local textColor = completed and theme.colors.onPrimary
				or (current and theme.colors.onPrimaryContainer or theme.colors.onSurfaceVariant)

			Motion.tween(data.circle, { BackgroundColor3 = fill }, token)
			Motion.tween(data.stroke, {
				Color = completed and theme.colors.primary or (current and theme.colors.primary or theme.colors.outline),
				Transparency = current and 0 or 0,
			}, token)
			Motion.tween(data.label, { TextColor3 = textColor }, token)
			if data.icon then
				Motion.tween(data.icon, { ImageColor3 = textColor, ImageTransparency = completed and 0 or 1 }, token)
				data.label.Visible = not completed
			end
			if data.connector then
				Motion.tween(data.connector, {
					BackgroundColor3 = completed and theme.colors.primary or theme.colors.outlineVariant,
				}, token)
			end
			if data.caption then
				Motion.tween(data.caption, { TextColor3 = current and theme.colors.primary or theme.colors.onSurface }, token)
			end
		end
	end

	function handle:Set(value, skipCallback)
		local count = #self.steps
		if count == 0 then
			return
		end
		self.value = math.clamp(math.floor(value or 1), 1, count)
		self:_render(true)
		if not skipCallback and props.Callback then
			task.spawn(props.Callback, self.value)
		end
		if self.window and self.flag then
			self.window:_persist(self)
		end
	end

	function handle:Get()
		return self.value
	end

	function handle:_refreshTheme()
		if not self.main then
			return
		end
		self:_render(false)
	end

	function handle:_destroy()
		Element.destroy(self)
	end

	return handle
end

return { new = Stepper.new }
