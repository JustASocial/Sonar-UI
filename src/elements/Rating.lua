local Element = require(script.Parent.Parent.core.Element)
local Row = require(script.Parent.Parent.core.Row)
local Creator = require(script.Parent.Parent.core.Creator)
local Motion = require(script.Parent.Parent.core.Motion)
local Icons = require(script.Parent.Parent.icons.Init)

local Rating = {}

local STAR = 26
local GAP = 4

function Rating.new(ctx)
	local props = ctx.props or {}
	local handle = Element.new({
		typeName = "Rating",
		window = ctx.window,
		container = ctx.container,
		props = props,
	})
	handle.max = props.Max or 5
	handle.value = props.Value or 0

	function handle:_build(parentFrame, order)
		local window = self.window
		local theme = window.theme
		Creator.window = window

		local width = self.max * STAR + (self.max - 1) * GAP

		Row.build(self, {
			title = props.Title,
			description = props.Description,
			icon = props.Icon,
			controlWidth = width,
			parent = parentFrame,
			order = order,
		})

		local content = self.content

		local row = Creator.new("Frame", {
			Name = "Stars",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(width, STAR),
			BackgroundTransparency = 1,
			Parent = content,
		})
		self.row = row

		Creator.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, GAP),
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Parent = row,
		})

		self.stars = {}
		for index = 1, self.max do
			local star = Creator.new("TextButton", {
				Size = UDim2.fromOffset(STAR, STAR),
				BackgroundTransparency = 1,
				AutoButtonColor = false,
				Text = "",
				LayoutOrder = index,
				Parent = row,
			})
			local icon = Creator.new("ImageLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Image = Icons.image(props.Icon or "star") or "",
				ImageColor3 = theme.colors.onSurfaceVariant,
				ScaleType = Enum.ScaleType.Fit,
				Parent = star,
			}, { ImageColor3 = "onSurfaceVariant" })
			self.stars[index] = { star = star, icon = icon }

			Element.connect(self, star.MouseEnter, function()
				Motion.tween(icon, { ImageColor3 = theme.colors.primary }, theme.motion.short)
			end)
			Element.connect(self, star.MouseLeave, function()
				self:_render()
			end)
			Element.connect(self, star.MouseButton1Click, function()
				if self.locked or props.ReadOnly then
					return
				end
				self:Set(index, true)
				if props.Callback then
					task.spawn(props.Callback, index)
				end
			end)
		end

		self:_render()
	end

	function handle:_render()
		local theme = self.window.theme
		for index, data in ipairs(self.stars) do
			local filled = index <= self.value
			Motion.tween(data.icon, {
				ImageColor3 = filled and theme.colors.primary or theme.colors.onSurfaceVariant,
			}, theme.motion.short)
		end
	end

	function handle:Set(value, skipCallback)
		self.value = math.clamp(math.floor(value or 0), 0, self.max)
		if self.main then
			self:_render()
		end
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
		Row.refreshTheme(self)
		self:_render()
	end

	function handle:_destroy()
		Element.destroy(self)
	end

	return handle
end

return { new = Rating.new }
