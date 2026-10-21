local Element = require(script.Parent.Parent.core.Element)
local Creator = require(script.Parent.Parent.core.Creator)
local Motion = require(script.Parent.Parent.core.Motion)
local Variables = require(script.Parent.Parent.core.Variables)
local Icons = require(script.Parent.Parent.icons.Init)

local ColorPicker = {}

local function rgbToHsv(color)
	local r, g, b = color.R, color.G, color.B
	local max = math.max(r, g, b)
	local min = math.min(r, g, b)
	local delta = max - min
	local h = 0
	if delta > 0 then
		if max == r then
			h = (60 * ((g - b) / delta)) % 360
		elseif max == g then
			h = (60 * ((b - r) / delta) + 120) % 360
		else
			h = (60 * ((r - g) / delta) + 240) % 360
		end
	end
	local s = 0
	if max > 0 then
		s = delta / max
	end
	return h / 360, s, max
end

local function hsvToRgb(h, s, v)
	local i = math.floor(h * 6)
	local f = h * 6 - i
	local p = v * (1 - s)
	local q = v * (1 - f * s)
	local t = v * (1 - (1 - f) * s)
	local r, g, b = 0, 0, 0
	if i % 6 == 0 then
		r, g, b = v, t, p
	elseif i % 6 == 1 then
		r, g, b = q, v, p
	elseif i % 6 == 2 then
		r, g, b = p, v, t
	elseif i % 6 == 3 then
		r, g, b = p, q, v
	elseif i % 6 == 4 then
		r, g, b = t, p, v
	else
		r, g, b = v, p, q
	end
	return Color3.new(r, g, b)
end

local function hueGradient()
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
		ColorSequenceKeypoint.new(1 / 6, Color3.fromRGB(255, 255, 0)),
		ColorSequenceKeypoint.new(2 / 6, Color3.fromRGB(0, 255, 0)),
		ColorSequenceKeypoint.new(3 / 6, Color3.fromRGB(0, 255, 255)),
		ColorSequenceKeypoint.new(4 / 6, Color3.fromRGB(0, 0, 255)),
		ColorSequenceKeypoint.new(5 / 6, Color3.fromRGB(255, 0, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
	})
end

function ColorPicker.new(ctx)
	local props = ctx.props or {}
	local handle = Element.new({
		typeName = "ColorPicker",
		window = ctx.window,
		container = ctx.container,
		props = props,
	})
	handle.value = props.Color or Color3.fromRGB(255, 255, 255)
	handle.alpha = props.Alpha or 0

	function handle:_build(parentFrame, order)
		local window = self.window
		local theme = window.theme
		Creator.window = window

		local main = Creator.new("Frame", {
			Name = "ColorPicker",
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, props.Description and 76 or 60),
			BackgroundTransparency = 1,
			Parent = parentFrame,
		})
		self.main = main

		local title = Creator.new("TextLabel", {
			Position = UDim2.new(0, 0, 0, 8),
			Size = UDim2.new(1, -56, 0, 24),
			BackgroundTransparency = 1,
			Font = theme.fonts.bold,
			Text = props.Title or "",
			TextColor3 = theme.colors.onSurface,
			TextSize = theme.type.titleMedium.size,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = main,
		}, { TextColor3 = "onSurface" })
		self.title = title

		if props.Description then
			local desc = Creator.new("TextLabel", {
				Position = UDim2.new(0, 0, 0, 32),
				Size = UDim2.new(1, -56, 0, 18),
				BackgroundTransparency = 1,
				Font = theme.fonts.regular,
				Text = props.Description,
				TextColor3 = theme.colors.onSurfaceVariant,
				TextSize = theme.type.bodySmall.size,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = main,
			}, { TextColor3 = "onSurfaceVariant" })
			self.desc = desc
		end

		local swatch = Creator.new("TextButton", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 8),
			Size = UDim2.fromOffset(44, 44),
			BackgroundColor3 = self.value,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			Parent = main,
		}, { BackgroundColor3 = "surface" })
		self.swatch = swatch

		Creator.new("UICorner", {
			CornerRadius = theme.shape.field,
			Parent = swatch,
		})
		Creator.new("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = theme.colors.outlineVariant,
			Transparency = 0,
			Thickness = 1,
			Parent = swatch,
		}, { Color = "outlineVariant" })

		local hover = Creator.new("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = theme.colors.onSurface,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Parent = swatch,
		}, { BackgroundColor3 = "onSurface" })
		self.state = hover

		Element.connect(self, swatch.MouseEnter, function()
			Motion.tween(hover, { BackgroundTransparency = 1 - theme.state.hover }, theme.motion.short)
		end)
		Element.connect(self, swatch.MouseLeave, function()
			Motion.tween(hover, { BackgroundTransparency = 1 }, theme.motion.short)
		end)
		Element.connect(self, swatch.MouseButton1Click, function()
			if self.locked then
				return
			end
			self:open()
		end)

		self:_render()
	end

	function handle:_render()
		if not self.swatch then
			return
		end
		self.swatch.BackgroundColor3 = self.value
	end

	function handle:open()
		if self.dialog then
			return
		end
		local window = self.window
		local theme = window.theme
		local overlay = window.overlayGui

		local scrim = Creator.new("Frame", {
			Name = "ColorScrim",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = theme.colors.scrim,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Parent = overlay,
		}, { BackgroundColor3 = "scrim" })

		local dialog = Creator.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(324, 400),
			BackgroundColor3 = theme.colors.surfaceContainerHigh,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Parent = scrim,
		}, { BackgroundColor3 = "surfaceContainerHigh" })
		self.dialog = dialog

		Creator.new("UICorner", {
			CornerRadius = theme.shape.dialog,
			Parent = dialog,
		})

		local stack = Creator.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 12),
			Parent = dialog,
		})

		Creator.new("UIPadding", {
			PaddingTop = UDim.new(0, 20),
			PaddingBottom = UDim.new(0, 20),
			PaddingLeft = UDim.new(0, 20),
			PaddingRight = UDim.new(0, 20),
			Parent = dialog,
		})

		local heading = Creator.new("TextLabel", {
			Size = UDim2.new(1, 0, 0, 26),
			BackgroundTransparency = 1,
			Font = theme.fonts.bold,
			Text = props.Title or "Colour",
			TextColor3 = theme.colors.onSurface,
			TextSize = theme.type.titleLarge.size,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = dialog,
		}, { TextColor3 = "onSurface" })
		heading.LayoutOrder = 1

		local previewRow = Creator.new("Frame", {
			Size = UDim2.new(1, 0, 0, 56),
			BackgroundTransparency = 1,
			Parent = dialog,
		})
		previewRow.LayoutOrder = 2

		local preview = Creator.new("Frame", {
			Size = UDim2.fromOffset(56, 56),
			BackgroundColor3 = self.value,
			BorderSizePixel = 0,
			Parent = previewRow,
		}, { BackgroundColor3 = "surface" })
		Creator.new("UICorner", {
			CornerRadius = UDim.new(0, 12),
			Parent = preview,
		})
		Creator.new("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = theme.colors.outlineVariant,
			Transparency = 0,
			Thickness = 1,
			Parent = preview,
		}, { Color = "outlineVariant" })
		self.preview = preview

		local previewText = Creator.new("TextLabel", {
			Position = UDim2.new(0, 72, 0, 4),
			Size = UDim2.new(1, -72, 0, 20),
			BackgroundTransparency = 1,
			Font = theme.fonts.mono,
			Text = "",
			TextColor3 = theme.colors.onSurface,
			TextSize = theme.type.bodyMedium.size,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = previewRow,
		}, { TextColor3 = "onSurface" })
		self.previewText = previewText

		local plane = Creator.new("Frame", {
			Size = UDim2.new(1, 0, 0, 150),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Parent = dialog,
		}, { BackgroundColor3 = "surface" })
		plane.LayoutOrder = 3
		self.plane = plane

		Creator.new("UICorner", { CornerRadius = UDim.new(0, 10), Parent = plane })

		Creator.new("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0, 0, 0)),
			Parent = plane,
		})

		local sat = Creator.new("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.new(1, 0, 0),
			BorderSizePixel = 0,
			Parent = plane,
		})
		Creator.new("UICorner", { CornerRadius = UDim.new(0, 10), Parent = sat })
		Creator.new("UIGradient", {
			Rotation = 0,
			Color = ColorSequence.new(Color3.new(1, 1, 1)),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Parent = sat,
		})
		self.sat = sat

		local cursor = Creator.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(18, 18),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Parent = plane,
		})
		Creator.new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = cursor })
		Creator.new("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = Color3.new(0, 0, 0),
			Transparency = 0.15,
			Thickness = 3,
			Parent = cursor,
		})
		self.cursor = cursor

		local hueTrack = Creator.new("Frame", {
			Size = UDim2.new(1, 0, 0, 14),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Parent = dialog,
		}, { BackgroundColor3 = "surface" })
		hueTrack.LayoutOrder = 4
		Creator.new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = hueTrack })
		Creator.new("UIGradient", {
			Color = hueGradient(),
			Parent = hueTrack,
		})

		local hueCursor = Creator.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(14, 22),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Parent = hueTrack,
		})
		Creator.new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = hueCursor })
		Creator.new("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = Color3.new(0, 0, 0),
			Transparency = 0.2,
			Thickness = 2,
			Parent = hueCursor,
		})
		self.hueCursor = hueCursor

		local alphaTrack = nil
		local alphaCursor = nil
		if props.Alpha ~= nil then
			alphaTrack = Creator.new("Frame", {
				Size = UDim2.new(1, 0, 0, 14),
				BackgroundColor3 = self.value,
				BorderSizePixel = 0,
				Parent = dialog,
			}, { BackgroundColor3 = "surface" })
			alphaTrack.LayoutOrder = 5
			Creator.new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = alphaTrack })
			Creator.new("UIGradient", {
				Rotation = 0,
				Color = ColorSequence.new(self.value),
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(1, 0),
				}),
				Parent = alphaTrack,
			})
			alphaCursor = Creator.new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromOffset(14, 22),
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				Parent = alphaTrack,
			})
			Creator.new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = alphaCursor })
			Creator.new("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = Color3.new(0, 0, 0),
				Transparency = 0.2,
				Thickness = 2,
				Parent = alphaCursor,
			})
		end

		local hexBox = Creator.new("TextBox", {
			Size = UDim2.new(1, 0, 0, 44),
			BackgroundColor3 = theme.colors.surfaceContainerHighest,
			BorderSizePixel = 0,
			Text = "",
			PlaceholderText = "#RRGGBB",
			PlaceholderColor3 = theme.colors.onSurfaceVariant,
			TextColor3 = theme.colors.onSurface,
			TextSize = theme.type.bodyMedium.size,
			Font = theme.fonts.mono,
			ClearTextOnFocus = false,
			Parent = dialog,
		}, { BackgroundColor3 = "surfaceContainerHighest" })
		hexBox.LayoutOrder = 6
		Creator.new("UICorner", { CornerRadius = UDim.new(0, 8), Parent = hexBox })
		Creator.new("UIPadding", {
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
			Parent = hexBox,
		})
		self.hexBox = hexBox

		local actions = Creator.new("Frame", {
			Size = UDim2.new(1, 0, 0, 40),
			BackgroundTransparency = 1,
			Parent = dialog,
		})
		actions.LayoutOrder = 7
		Creator.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = actions,
		})

		local state = { h = 0, s = 0, v = 1, a = self.alpha }
		local dragging = nil
		local moveConnection = nil
		local endConnection = nil

		local function applyColor()
			self.value = hsvToRgb(state.h, state.s, state.v)
			self.alpha = state.a
			self:_render()
			preview.BackgroundColor3 = self.value
			previewText.Text = string.format("%s  %d%%", self.value:ToHex(), math.floor(state.a * 100))
			if alphaTrack then
				alphaTrack.BackgroundColor3 = self.value
			end
			hexBox.Text = self.value:ToHex()
		end

		local function updateFromPlane(position)
			local size = plane.AbsoluteSize
			if size.X <= 0 or size.Y <= 0 then
				return
			end
			state.s = math.clamp((position.X - plane.AbsolutePosition.X) / size.X, 0, 1)
			state.v = math.clamp(1 - (position.Y - plane.AbsolutePosition.Y) / size.Y, 0, 1)
			applyColor()
		end

		local function updateFromHue(position)
			local size = hueTrack.AbsoluteSize
			if size.X <= 0 then
				return
			end
			state.h = math.clamp((position.X - hueTrack.AbsolutePosition.X) / size.X, 0, 1)
			sat.BackgroundColor3 = hsvToRgb(state.h, 1, 1)
			applyColor()
		end

		local function updateFromAlpha(position)
			local size = alphaTrack.AbsoluteSize
			if size.X <= 0 then
				return
			end
			state.a = math.clamp((position.X - alphaTrack.AbsolutePosition.X) / size.X, 0, 1)
			applyColor()
		end

		local function stopDrag()
			dragging = nil
			if moveConnection then
				moveConnection:Disconnect()
				moveConnection = nil
			end
			if endConnection then
				endConnection:Disconnect()
				endConnection = nil
			end
		end

		local function beginDrag(kind)
			dragging = kind
			if moveConnection then
				moveConnection:Disconnect()
			end
			if endConnection then
				endConnection:Disconnect()
			end
			moveConnection = Variables.services.UserInputService.InputChanged:Connect(function(changed)
				if dragging ~= kind then
					return
				end
				if changed.UserInputType == Enum.UserInputType.MouseMovement or changed.UserInputType == Enum.UserInputType.Touch then
					if kind == "plane" then
						updateFromPlane(changed.Position)
					elseif kind == "hue" then
						updateFromHue(changed.Position)
					elseif kind == "alpha" then
						updateFromAlpha(changed.Position)
					end
				end
			end)
			endConnection = Variables.services.UserInputService.InputEnded:Connect(function()
				stopDrag()
			end)
		end

		plane.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				beginDrag("plane")
				updateFromPlane(input.Position)
			end
		end)
		hueTrack.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				beginDrag("hue")
				updateFromHue(input.Position)
			end
		end)
		if alphaTrack then
			alphaTrack.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					beginDrag("alpha")
					updateFromAlpha(input.Position)
				end
			end)
		end

		hexBox.FocusLost:Connect(function()
			local text = hexBox.Text:gsub("#", "")
			if #text == 6 then
				local ok, color = pcall(Color3.fromHex, text)
				if ok then
					local h, s, v = rgbToHsv(color)
					state.h = h
					state.s = s
					state.v = v
					sat.BackgroundColor3 = hsvToRgb(state.h, 1, 1)
					applyColor()
				end
			end
		end)

		local function makeButton(text, order, primary)
			local button = Creator.new("TextButton", {
				Size = UDim2.new(0, 0, 0, 40),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundColor3 = primary and theme.colors.primary or theme.colors.surfaceContainerHighest,
				BackgroundTransparency = primary and 0 or 0,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Text = text,
				Font = theme.fonts.bold,
				TextColor3 = primary and theme.colors.onPrimary or theme.colors.onSurface,
				TextSize = theme.type.labelLarge.size,
				LayoutOrder = order,
				Parent = actions,
			}, {
				BackgroundColor3 = primary and "primary" or "surfaceContainerHighest",
				TextColor3 = primary and "onPrimary" or "onSurface",
			})
			Creator.new("UICorner", {
				CornerRadius = theme.shape.button,
				Parent = button,
			})
			Creator.new("UIPadding", {
				PaddingLeft = UDim.new(0, 20),
				PaddingRight = UDim.new(0, 20),
				Parent = button,
			})
			return button
		end

		local cancel = makeButton("Cancel", 1, false)
		local apply = makeButton("Apply", 2, true)

		local function close()
			stopDrag()
			self.dialog = nil
			Motion.tween(scrim, { BackgroundTransparency = 1 }, theme.motion.emphasizedAccelerate)
			Motion.tween(dialog, { BackgroundTransparency = 1 }, theme.motion.emphasizedAccelerate)
			task.delay(theme.motion.emphasizedAccelerate.time, function()
				scrim:Destroy()
			end)
		end

		cancel.MouseButton1Click:Connect(function()
			close()
		end)
		apply.MouseButton1Click:Connect(function()
			self:Set(self.value, self.alpha, true)
			close()
		end)

		local h, s, v = rgbToHsv(self.value)
		state.h = h
		state.s = s
		state.v = v
		state.a = self.alpha
		sat.BackgroundColor3 = hsvToRgb(state.h, 1, 1)
		applyColor()

		local function placeCursors()
			cursor.Position = UDim2.new(state.s, 0, 1 - state.v, 0)
			hueCursor.Position = UDim2.new(state.h, 0, 0.5, 0)
			if alphaCursor then
				alphaCursor.Position = UDim2.new(state.a, 0, 0.5, 0)
			end
		end
		placeCursors()
		Element.connect(self, plane:GetPropertyChangedSignal("AbsoluteSize"), placeCursors)
		Element.connect(self, hueTrack:GetPropertyChangedSignal("AbsoluteSize"), placeCursors)

		Motion.tween(scrim, { BackgroundTransparency = 0.6 }, theme.motion.emphasizedDecelerate)
		Motion.tween(dialog, { BackgroundTransparency = 0 }, theme.motion.emphasizedDecelerate)
	end

	function handle:Set(color, alpha, skipCallback)
		self.value = color
		if alpha ~= nil then
			self.alpha = alpha
		end
		self:_render()
		if not skipCallback and props.Callback then
			task.spawn(props.Callback, self.value, self.alpha)
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
		local theme = self.window.theme
		self.title.TextColor3 = theme.colors.onSurface
		if self.desc then
			self.desc.TextColor3 = theme.colors.onSurfaceVariant
		end
	end

	function handle:_destroy()
		if self.dialog then
			self.dialog:Destroy()
			self.dialog = nil
		end
		Element.destroy(self)
	end

	return handle
end

return { new = ColorPicker.new }
