local Element = require(script.Parent.Parent.core.Element)
local Creator = require(script.Parent.Parent.core.Creator)
local Motion = require(script.Parent.Parent.core.Motion)
local Icons = require(script.Parent.Parent.icons.Init)
local Scroll = require(script.Parent.Parent.core.Scroll)
local Variables = require(script.Parent.Parent.core.Variables)

local Code = {}

local KEYWORDS = {
	["and"] = true,
	["break"] = true,
	["do"] = true,
	["else"] = true,
	["elseif"] = true,
	["end"] = true,
	["false"] = true,
	["for"] = true,
	["function"] = true,
	["if"] = true,
	["in"] = true,
	["local"] = true,
	["nil"] = true,
	["not"] = true,
	["or"] = true,
	["repeat"] = true,
	["return"] = true,
	["then"] = true,
	["true"] = true,
	["until"] = true,
	["while"] = true,
	["continue"] = true,
	["export"] = true,
	["type"] = true,
}

local function highlight(source, palette)
	local result = {}
	local index = 1
	local length = #source

	while index <= length do
		local char = source:sub(index, index)
		local two = source:sub(index, index + 1)

		if source:sub(index, index + 1) == "--" then
			local stop = source:find("\n", index) or (length + 1)
			table.insert(result, string.format('<font color="%s">%s</font>', palette.comment, source:sub(index, stop - 1)))
			index = stop
		elseif char == '"' or char == "'" then
			local stop = index + 1
			while stop <= length do
				if source:sub(stop, stop) == "\\" then
					stop = stop + 2
				elseif source:sub(stop, stop) == char then
					break
				else
					stop = stop + 1
				end
			end
			local text = source:sub(index, math.min(stop, length))
			table.insert(result, string.format('<font color="%s">%s</font>', palette.string, text))
			index = math.min(stop + 1, length + 1)
		elseif char:match("%d") then
			local stop = index
			while stop <= length and source:sub(stop, stop):match("[%d%.xXa-fA-F]") do
				stop = stop + 1
			end
			table.insert(result, string.format('<font color="%s">%s</font>', palette.number, source:sub(index, stop - 1)))
			index = stop
		elseif char:match("[%a_]") then
			local stop = index
			while stop <= length and source:sub(stop, stop):match("[%w_]") do
				stop = stop + 1
			end
			local word = source:sub(index, stop - 1)
			if KEYWORDS[word] then
				table.insert(result, string.format('<font color="%s">%s</font>', palette.keyword, word))
			else
				table.insert(result, word)
			end
			index = stop
		elseif two == "==" or two == "~=" or two == "<=" or two == ">=" or two == ".." or two == "->" or two == "::" then
			table.insert(result, string.format('<font color="%s">%s</font>', palette.operator, tostring(two)))
			index = index + 2
		else
			table.insert(result, char)
			index = index + 1
		end
	end

	return table.concat(result)
end

function Code.new(ctx)
	local props = ctx.props or {}
	local handle = Element.new({
		typeName = "Code",
		window = ctx.window,
		container = ctx.container,
		props = props,
	})

	function handle:_build(parentFrame, order)
		local window = self.window
		local theme = window.theme
		Creator.window = window

		local palette = {
			comment = theme.colors.onSurfaceVariant:ToHex(),
			string = theme.colors.tertiary:ToHex(),
			number = theme.colors.primary:ToHex(),
			keyword = theme.colors.secondary:ToHex(),
			operator = theme.colors.onSurfaceVariant:ToHex(),
		}

		local main = Creator.new("Frame", {
			Name = "Code",
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, props.Height or 0),
			AutomaticSize = props.Height and Enum.AutomaticSize.None or Enum.AutomaticSize.Y,
			BackgroundColor3 = theme.colors.surfaceContainerLow,
			BorderSizePixel = 0,
			Parent = parentFrame,
		}, { BackgroundColor3 = "surfaceContainerLow" })
		self.main = main

		Creator.new("UICorner", {
			CornerRadius = theme.shape.card,
			Parent = main,
		})

		local header = Creator.new("Frame", {
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundTransparency = 1,
			Parent = main,
		})

		local title = Creator.new("TextLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 14, 0.5, 0),
			Size = UDim2.new(1, -70, 1, 0),
			BackgroundTransparency = 1,
			Font = theme.fonts.bold,
			Text = props.Title or "code",
			TextColor3 = theme.colors.onSurfaceVariant,
			TextSize = theme.type.labelMedium.size,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = header,
		}, { TextColor3 = "onSurfaceVariant" })
		self.title = title

		local copy = Creator.new("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(24, 24),
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Text = "",
			Parent = header,
		})

		local copyIcon = Creator.new("ImageLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Image = Icons.image("copy") or "",
			ImageColor3 = theme.colors.onSurfaceVariant,
			ScaleType = Enum.ScaleType.Fit,
			Parent = copy,
		}, { ImageColor3 = "onSurfaceVariant" })
		self.copyIcon = copyIcon

		Element.connect(self, copy.MouseButton1Click, function()
			Variables.setClipboard(props.Code or "")
			Motion.tween(copyIcon, { Image = Icons.image("check") or "" }, theme.motion.short4)
			task.delay(1.2, function()
				if copyIcon.Parent then
					Motion.tween(copyIcon, { Image = Icons.image("copy") or "" }, theme.motion.short4)
				end
			end)
		end)

		local scroller = Creator.new("ScrollingFrame", {
			Size = UDim2.new(1, 0, props.Height and 1 or 0, props.Height and 0 or 0),
			AutomaticSize = props.Height and Enum.AutomaticSize.None or Enum.AutomaticSize.Y,
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

		local code = Creator.new("TextLabel", {
			Size = UDim2.new(1, -24, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Font = theme.fonts.mono,
			RichText = true,
			Text = "",
			TextColor3 = theme.colors.onSurface,
			TextSize = props.CodeSize or 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextWrapped = props.Wrap ~= false,
			Parent = scroller,
		}, { TextColor3 = "onSurface" })
		self.code = code

		Creator.new("UIPadding", {
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 12),
			PaddingLeft = UDim.new(0, 14),
			PaddingRight = UDim.new(0, 14),
			Parent = scroller,
		})

		Scroll.bindContent(scroller, code, "Y", 20)

		self:Set(props.Code or "")
	end

	function handle:Set(source)
		self.source = source
		if not self.code then
			return
		end
		local theme = self.window.theme
		local palette = {
			comment = theme.colors.onSurfaceVariant:ToHex(),
			string = theme.colors.tertiary:ToHex(),
			number = theme.colors.primary:ToHex(),
			keyword = theme.colors.secondary:ToHex(),
			operator = theme.colors.onSurfaceVariant:ToHex(),
		}
		self.code.Text = highlight(source or "", palette)
	end

	function handle:_refreshTheme()
		if not self.main then
			return
		end
		local theme = self.window.theme
		self.main.BackgroundColor3 = theme.colors.surfaceContainerLow
		self.title.TextColor3 = theme.colors.onSurfaceVariant
		self.code.TextColor3 = theme.colors.onSurface
		self:Set(self.source or "")
	end

	function handle:_destroy()
		Element.destroy(self)
	end

	return handle
end

return { new = Code.new }
