local Scroll = {}

local function applyCanvas(scroller, width, height)
	local current = scroller.CanvasSize
	if current.X.Offset == width and current.Y.Offset == height then
		return
	end
	scroller.CanvasSize = UDim2.new(0, width, 0, height)
end

function Scroll.bindContent(scroller, content, mode, padding)
	padding = padding or 0

	local function update()
		local size = content.AbsoluteSize
		if mode == "X" then
			local width = math.ceil(size.X + padding)
			if width <= 0 then
				return
			end
			applyCanvas(scroller, width, size.Y)
		else
			local height = math.ceil(size.Y + padding)
			if height <= 0 then
				return
			end
			applyCanvas(scroller, size.X, height)
		end
	end

	content:GetPropertyChangedSignal("AbsoluteSize"):Connect(update)
	update()
	return update
end

function Scroll.bindLayout(scroller, layout, mode, padding)
	padding = padding or 0

	local function update()
		local size = layout.AbsoluteContentSize
		if mode == "X" then
			local width = math.ceil(size.X + padding)
			if width <= 0 then
				return
			end
			applyCanvas(scroller, width, scroller.AbsoluteSize.Y)
		else
			local height = math.ceil(size.Y + padding)
			if height <= 0 then
				return
			end
			applyCanvas(scroller, scroller.AbsoluteSize.X, height)
		end
	end

	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update)
	update()
	return update
end

return Scroll
