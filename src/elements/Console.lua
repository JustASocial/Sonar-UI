local Element = require(script.Parent.Parent.core.Element)
local Scroll = require(script.Parent.Parent.core.Scroll)
local Creator = require(script.Parent.Parent.core.Creator)

local Console = {}

local LEVELS = {
	info = "onSurface",
	warn = "tertiary",
	error = "error",
	success = "primary",
}

function Console.new(ctx)
	local props = ctx.props or {}
	local handle = Element.new({
		typeName = "Console",
		window = ctx.window,
		container = ctx.container,
		props = props,
	})
	handle.lines = {}
	handle.labels = {}
	handle.head = 1
	handle.order = 0

	function handle:write(text, level)
		level = level or "info"
		text = tostring(text)

		local maxLines = props.MaxLines or 60

		if #self.lines >= maxLines then
			table.move(self.lines, 2, #self.lines, 1)
			self.lines[#self.lines] = text
		else
			table.insert(self.lines, text)
		end

		if not self.scroller then
			if props.Callback then
				task.spawn(props.Callback, text, level)
			end
			return
		end

		local theme = self.window.theme
		local color = theme.colors[LEVELS[level] or "onSurface"]
		self.order = self.order + 1

		local label
		if #self.lines <= maxLines and #self.labels < #self.lines then
			local index = #self.lines
			label = self.labels[index]
			if not label then
				label = Creator.new("TextLabel", {
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					Font = theme.fonts.mono,
					Text = "",
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					TextWrapped = true,
					Parent = self.scroller,
				})
				self.labels[index] = label
			end
		else
			label = self.labels[self.head]
			self.head = (self.head % maxLines) + 1
		end

		if label then
			label.LayoutOrder = self.order
			label.Text = text
			label.TextColor3 = color
			label.Visible = true
		end

		if props.Follow ~= false then
			task.defer(function()
				if self.scroller and self.scroller.Parent then
					self.scroller.CanvasPosition = Vector2.new(0, self.scroller.AbsoluteCanvasSize.Y)
				end
			end)
		end

		if props.Callback then
			task.spawn(props.Callback, text, level)
		end
	end

	function handle:clear()
		self.lines = {}
		self.head = 1
		self.order = 0
		for _, label in ipairs(self.labels) do
			label.Visible = false
		end
	end

	function handle:getText()
		return table.concat(self.lines, "\n")
	end

	function handle:_build(parentFrame, order)
		local window = self.window
		local theme = window.theme
		Creator.window = window

		local height = props.Height or 160

		local main = Creator.new("Frame", {
			Name = "Console",
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, height),
			BackgroundColor3 = theme.colors.surfaceContainerLow,
			BorderSizePixel = 0,
			Parent = parentFrame,
		}, { BackgroundColor3 = "surfaceContainerLow" })
		self.main = main

		Creator.new("UICorner", {
			CornerRadius = theme.shape.card,
			Parent = main,
		})

		local scroller = Creator.new("ScrollingFrame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = theme.colors.outlineVariant,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ElasticBehavior = Enum.ElasticBehavior.Never,
			Parent = main,
		})
		self.scroller = scroller

		local listLayout = Creator.new("UIListLayout", {
			Padding = UDim.new(0, 2),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = scroller,
		})

		Creator.new("UIPadding", {
			PaddingTop = UDim.new(0, 10),
			PaddingBottom = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
			Parent = scroller,
		})

		Scroll.bindLayout(scroller, listLayout, "Y", 20)

		for _, text in ipairs(self.lines) do
			self:write(text, "info")
		end
	end

	function handle:_refreshTheme()
		if not self.main then
			return
		end
		self.main.BackgroundColor3 = self.window.theme.colors.surfaceContainerLow
	end

	function handle:_destroy()
		Element.destroy(self)
	end

	return handle
end

return { new = Console.new }
