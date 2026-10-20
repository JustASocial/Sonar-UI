local Element = require(script.Parent.Parent.core.Element)
local Creator = require(script.Parent.Parent.core.Creator)
local Motion = require(script.Parent.Parent.core.Motion)
local Variables = require(script.Parent.Parent.core.Variables)
local Icons = require(script.Parent.Parent.icons.Init)

local ImageUploader = {}

local DASH_LENGTH = 22

function ImageUploader.new(ctx)
	local props = ctx.props or {}
	local handle = Element.new({
		typeName = "ImageUploader",
		window = ctx.window,
		container = ctx.container,
		props = props,
	})
	handle.value = props.Image or nil

	local onSelect = props.Callback or props.OnSelect

	local function normalizeSource(source)
		if type(source) == "number" then
			return "rbxassetid://" .. tostring(source)
		end
		if type(source) ~= "string" then
			return nil
		end
		local trimmed = source:gsub("%s", "")
		if trimmed == "" then
			return nil
		end
		if trimmed:match("^%d+$") then
			return "rbxassetid://" .. trimmed
		end
		return trimmed
	end

	handle.setSource = function(self, source)
		local normalized = normalizeSource(source)
		self.value = normalized
		if self.preview then
			self.preview.Image = normalized or ""
		end
		if self.placeholder then
			self.placeholder.Visible = normalized == nil
		end
		if self.urlBox then
			self.urlBox.Text = normalized or ""
		end
		if self.clearButton then
			self.clearButton.Visible = normalized ~= nil
		end
		if onSelect and normalized ~= nil then
			task.spawn(onSelect, normalized)
		end
		if self.window and self.flag then
			self.window:_persist(self)
		end
	end

	function handle:_build(parentFrame, order)
		local window = self.window
		local theme = window.theme
		Creator.window = window

		local main = Creator.new("Frame", {
			Name = "ImageUploader",
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Parent = parentFrame,
		})
		self.main = main

		Creator.new("UIListLayout", {
			Padding = UDim.new(0, 8),
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

		local drop = Creator.new("Frame", {
			Size = UDim2.new(1, 0, 0, 132),
			BackgroundColor3 = theme.colors.surfaceContainerLow,
			BorderSizePixel = 0,
			Parent = main,
		}, { BackgroundColor3 = "surfaceContainerLow" })
		drop.LayoutOrder = 2
		self.drop = drop

		Creator.new("UICorner", {
			CornerRadius = theme.shape.card,
			Parent = drop,
		})

		local stroke = Creator.new("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = theme.colors.outlineVariant,
			Transparency = 0,
			Thickness = 1,
			Parent = drop,
		}, { Color = "outlineVariant" })
		self.stroke = stroke

		local preview = Creator.new("ImageLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Image = self.value or "",
			ScaleType = Enum.ScaleType.Fit,
			Parent = drop,
		})
		self.preview = preview

		local placeholder = Creator.new("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Parent = drop,
		})
		self.placeholder = placeholder

		local placeholderIcon = Creator.new("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.42, 0),
			Size = UDim2.fromOffset(32, 32),
			BackgroundTransparency = 1,
			Image = Icons.image("image") or "",
			ImageColor3 = theme.colors.onSurfaceVariant,
			ScaleType = Enum.ScaleType.Fit,
			Parent = placeholder,
		}, { ImageColor3 = "onSurfaceVariant" })

		local placeholderText = Creator.new("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.72, 0),
			Size = UDim2.new(0.8, 0, 0, 18),
			BackgroundTransparency = 1,
			Font = theme.fonts.regular,
			Text = props.Placeholder or "Paste an image link or drop a file",
			TextColor3 = theme.colors.onSurfaceVariant,
			TextSize = theme.type.bodySmall.size,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = placeholder,
		}, { TextColor3 = "onSurfaceVariant" })

		local urlBox = Creator.new("TextBox", {
			Size = UDim2.new(1, 0, 0, 40),
			BackgroundColor3 = theme.colors.surfaceContainerHighest,
			BorderSizePixel = 0,
			Text = self.value or "",
			PlaceholderText = "https://... or rbxassetid",
			PlaceholderColor3 = theme.colors.onSurfaceVariant,
			TextColor3 = theme.colors.onSurface,
			TextSize = theme.type.bodyMedium.size,
			Font = theme.fonts.regular,
			ClearTextOnFocus = false,
			Parent = main,
		}, { BackgroundColor3 = "surfaceContainerHighest" })
		urlBox.LayoutOrder = 3
		Creator.new("UICorner", { CornerRadius = UDim.new(0, 8), Parent = urlBox })
		Creator.new("UIPadding", {
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
			Parent = urlBox,
		})
		self.urlBox = urlBox

		local actions = Creator.new("Frame", {
			Size = UDim2.new(1, 0, 0, 36),
			BackgroundTransparency = 1,
			Parent = main,
		})
		actions.LayoutOrder = 4
		Creator.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			Padding = UDim.new(0, 8),
			Parent = actions,
		})

		local function makeButton(text, iconName, order, callback)
			local button = Creator.new("TextButton", {
				Size = UDim2.fromOffset(0, 36),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundColor3 = theme.colors.secondaryContainer,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Text = text,
				Font = theme.fonts.bold,
				TextColor3 = theme.colors.onSecondaryContainer,
				TextSize = theme.type.labelMedium.size,
				LayoutOrder = order,
				Parent = actions,
			}, {
				BackgroundColor3 = "secondaryContainer",
				TextColor3 = "onSecondaryContainer",
			})
			Creator.new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = button })
			Creator.new("UIPadding", {
				PaddingLeft = UDim.new(0, 16),
				PaddingRight = UDim.new(0, 16),
				Parent = button,
			})
			if iconName then
				local icon = Creator.new("ImageLabel", {
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 12, 0.5, 0),
					Size = UDim2.fromOffset(16, 16),
					BackgroundTransparency = 1,
					Image = Icons.image(iconName) or "",
					ImageColor3 = theme.colors.onSecondaryContainer,
					ScaleType = Enum.ScaleType.Fit,
					Parent = button,
				}, { ImageColor3 = "onSecondaryContainer" })
				button.TextXAlignment = Enum.TextXAlignment.Right
				Creator.new("UIPadding", {
					PaddingLeft = UDim.new(0, 36),
					PaddingRight = UDim.new(0, 16),
					Parent = button,
				})
			end
			Element.connect(self, button.MouseButton1Click, callback)
			return button
		end

		local pasteButton = makeButton("Paste", "clipboard", 1, function()
			local text = Variables.getClipboard()
			if text then
				self:setSource(text)
			end
		end)

		local clearButton = makeButton("Clear", "x", 2, function()
			self:setSource(nil)
		end)
		self.clearButton = clearButton

		local applyButton = makeButton("Apply", "check", 3, function()
			self:setSource(urlBox.Text)
		end)

		Element.connect(self, urlBox.FocusLost, function()
			local text = urlBox.Text
			if text ~= "" then
				self:setSource(text)
			end
		end)

		local dragging = false
		Element.connect(self, drop.InputBegan, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
				Motion.tween(stroke, { Color = theme.colors.primary }, theme.motion.short4)
			end
		end)
		Element.connect(self, drop.InputEnded, function()
			dragging = false
			Motion.tween(stroke, { Color = theme.colors.outlineVariant }, theme.motion.short4)
		end)

		self._pasteConnection = Element.connect(self, Variables.services.UserInputService.InputBegan, function(input, processed)
			if processed then
				return
			end
			if input.KeyCode == Enum.KeyCode.V and Variables.getClipboard then
				local text = Variables.getClipboard()
				if text and text:match("^https?://") or (text and text:match("^%d+$")) then
					self:setSource(text)
				end
			end
		end)

		self.placeholder.Visible = self.value == nil
		self.clearButton.Visible = self.value ~= nil
	end

	function handle:Set(value, skipCallback)
		local normalized = normalizeSource(value)
		self.value = normalized
		if self.preview then
			self.preview.Image = normalized or ""
		end
		if self.placeholder then
			self.placeholder.Visible = normalized == nil
		end
		if self.urlBox then
			self.urlBox.Text = normalized or ""
		end
		if self.clearButton then
			self.clearButton.Visible = normalized ~= nil
		end
		if not skipCallback and onSelect then
			task.spawn(onSelect, normalized)
		end
	end

	function handle:Get()
		return self.value
	end

	function handle:_refreshTheme()
		if not self.main then
			return
		end
		local theme = self.window.theme
		self.drop.BackgroundColor3 = theme.colors.surfaceContainerLow
		self.urlBox.BackgroundColor3 = theme.colors.surfaceContainerHighest
	end

	function handle:_destroy()
		Element.destroy(self)
	end

	return handle
end

return { new = ImageUploader.new }
