local Element = require(script.Parent.Parent.core.Element)
local Creator = require(script.Parent.Parent.core.Creator)
local Motion = require(script.Parent.Parent.core.Motion)
local Icons = require(script.Parent.Parent.icons.Init)

local ImageUploader = {}

local PREVIEW_HEIGHT = 150

function ImageUploader.new(ctx)
	local props = ctx.props or {}
	local handle = Element.new({
		typeName = "ImageUploader",
		window = ctx.window,
		container = ctx.container,
		props = props,
	})
	handle.variant = props.Variant or "input"
	handle.value = props.Image or nil

	local function normalize(source)
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
		local normalized = normalize(source)
		self.value = normalized
		if self.preview then
			self.preview.Image = normalized or ""
		end
		if self.emptyState then
			self.emptyState.Visible = normalized == nil
		end
		if self.urlBox then
			self.urlBox.Text = normalized or ""
		end
		if props.Callback and normalized ~= nil then
			task.spawn(props.Callback, normalized)
		end
		if self.window and self.flag then
			self.window:_persist(self)
		end
	end

	function handle:_build(parentFrame, order)
		local window = self.window
		local theme = window.theme
		Creator.window = window

		local preset = self.variant == "preset"

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
				LayoutOrder = 1,
				Parent = main,
			}, { TextColor3 = "onSurface" })
			self.title = title
		end

		if not preset then
			local field = Creator.new("Frame", {
				Name = "Field",
				Size = UDim2.new(1, 0, 0, 56),
				BackgroundColor3 = theme.colors.surfaceContainerHighest,
				BorderSizePixel = 0,
				LayoutOrder = 2,
				Parent = main,
			}, { BackgroundColor3 = "surfaceContainerHighest" })
			self.field = field

			Creator.new("UICorner", {
				CornerRadius = theme.shape.field,
				Parent = field,
			})

			local indicator = Creator.new("Frame", {
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, 0, 1, 0),
				Size = UDim2.new(1, 0, 0, 2),
				BackgroundColor3 = theme.colors.onSurfaceVariant,
				BackgroundTransparency = 0.7,
				BorderSizePixel = 0,
				Parent = field,
			}, { BackgroundColor3 = "onSurfaceVariant" })
			self.indicator = indicator

			local label = Creator.new("TextLabel", {
				Position = UDim2.new(0, 16, 0, 6),
				Size = UDim2.new(1, -32, 0, 16),
				BackgroundTransparency = 1,
				Font = theme.fonts.bold,
				Text = props.Placeholder or "Image id or link",
				TextColor3 = theme.colors.onSurfaceVariant,
				TextSize = theme.type.labelMedium.size,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = field,
			}, { TextColor3 = "onSurfaceVariant" })
			self.label = label

			local urlBox = Creator.new("TextBox", {
				Name = "TextBox",
				Position = UDim2.new(0, 16, 0, 24),
				Size = UDim2.new(1, -32, 1, -28),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = "",
				PlaceholderText = "",
				TextColor3 = theme.colors.onSurface,
				TextSize = theme.type.bodyLarge.size,
				Font = theme.fonts.regular,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				ClearTextOnFocus = false,
				Parent = field,
			}, { TextColor3 = "onSurface" })
			self.urlBox = urlBox

			Element.connect(self, urlBox.Focused, function()
				Motion.tween(indicator, {
					BackgroundColor3 = theme.colors.primary,
					BackgroundTransparency = 0,
				}, theme.motion.standard)
			end)

			Element.connect(self, urlBox.FocusLost, function()
				Motion.tween(indicator, {
					BackgroundColor3 = theme.colors.onSurfaceVariant,
					BackgroundTransparency = 0.7,
				}, theme.motion.standard)
				self:setSource(urlBox.Text)
			end)

			Element.connect(self, urlBox:GetPropertyChangedSignal("Text"), function()
				if urlBox.Text == "" then
					self:setSource(nil)
				end
			end)
		end

		local previewFrame = Creator.new("Frame", {
			Name = "Preview",
			Size = UDim2.new(1, 0, 0, PREVIEW_HEIGHT),
			BackgroundColor3 = theme.colors.surfaceContainerHighest,
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
			LayoutOrder = preset and 2 or 3,
			Parent = main,
		}, { BackgroundColor3 = "surfaceContainerHighest" })
		self.previewFrame = previewFrame

		Creator.new("UICorner", {
			CornerRadius = theme.shape.card,
			Parent = previewFrame,
		})
		Creator.new("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = theme.colors.outlineVariant,
			Transparency = 0,
			Thickness = 1,
			Parent = previewFrame,
		}, { Color = "outlineVariant" })

		local preview = Creator.new("ImageLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Image = self.value or "",
			ScaleType = Enum.ScaleType.Fit,
			Parent = previewFrame,
		})
		self.preview = preview

		local emptyState = Creator.new("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Visible = self.value == nil,
			Parent = previewFrame,
		})
		self.emptyState = emptyState

		local emptyIcon = Creator.new("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, -10),
			Size = UDim2.fromOffset(28, 28),
			BackgroundTransparency = 1,
			Image = Icons.image("image") or "",
			ImageColor3 = theme.colors.onSurfaceVariant,
			ScaleType = Enum.ScaleType.Fit,
			Parent = emptyState,
		}, { ImageColor3 = "onSurfaceVariant" })

		local emptyText = Creator.new("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 18),
			Size = UDim2.new(0.8, 0, 0, 18),
			BackgroundTransparency = 1,
			Font = theme.fonts.regular,
			Text = props.EmptyText or "Preview appears here",
			TextColor3 = theme.colors.onSurfaceVariant,
			TextSize = theme.type.bodySmall.size,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = emptyState,
		}, { TextColor3 = "onSurfaceVariant" })

		if props.Description then
			local desc = Creator.new("TextLabel", {
				Size = UDim2.new(1, 0, 0, 18),
				BackgroundTransparency = 1,
				Font = theme.fonts.regular,
				Text = props.Description,
				TextColor3 = theme.colors.onSurfaceVariant,
				TextSize = theme.type.bodySmall.size,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd,
				LayoutOrder = 4,
				Parent = main,
			}, { TextColor3 = "onSurfaceVariant" })
			self.desc = desc
		end
	end

	function handle:Set(value, skipCallback)
		local normalized = value
		if type(value) == "number" then
			normalized = "rbxassetid://" .. tostring(value)
		end
		self.value = normalized
		if self.preview then
			self.preview.Image = normalized or ""
		end
		if self.emptyState then
			self.emptyState.Visible = normalized == nil
		end
		if self.urlBox then
			self.urlBox.Text = normalized or ""
		end
		if not skipCallback and props.Callback then
			task.spawn(props.Callback, normalized)
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
		if self.title then
			self.title.TextColor3 = theme.colors.onSurface
		end
		if self.field then
			self.field.BackgroundColor3 = theme.colors.surfaceContainerHighest
		end
		if self.previewFrame then
			self.previewFrame.BackgroundColor3 = theme.colors.surfaceContainerHighest
		end
		if self.desc then
			self.desc.TextColor3 = theme.colors.onSurfaceVariant
		end
	end

	function handle:_destroy()
		Element.destroy(self)
	end

	return handle
end

return { new = ImageUploader.new }
