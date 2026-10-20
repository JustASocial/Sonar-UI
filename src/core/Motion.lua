local Variables = require(script.Parent.Variables)

local Motion = {}

local DEFAULT_TOKEN = {
	time = 0.25,
	style = Enum.EasingStyle.Quad,
	direction = Enum.EasingDirection.Out,
}

function Motion.resolve(token)
	if token == nil then
		return DEFAULT_TOKEN
	end
	if type(token) == "number" then
		return { time = token, style = DEFAULT_TOKEN.style, direction = DEFAULT_TOKEN.direction }
	end
	if type(token) == "table" then
		return {
			time = token.time or DEFAULT_TOKEN.time,
			style = token.style or DEFAULT_TOKEN.style,
			direction = token.direction or DEFAULT_TOKEN.direction,
		}
	end
	return DEFAULT_TOKEN
end

local ACTIVE = setmetatable({}, { __mode = "k" })

function Motion.tween(target, properties, token)
	local resolved = Motion.resolve(token)
	local tween = Variables.services.TweenService:Create(
		target,
		TweenInfo.new(resolved.time, resolved.style, resolved.direction),
		properties
	)
	ACTIVE[target] = tween
	tween:Play()
	return tween
end

function Motion.cancel(target)
	local tween = ACTIVE[target]
	if tween then
		tween:Cancel()
		ACTIVE[target] = nil
	end
end

function Motion.tweenColor(target, property, color, token)
	return Motion.tween(target, { [property] = color }, token)
end

function Motion.spring(target, properties, token)
	local resolved = Motion.resolve(token)
	return Motion.tween(
		target,
		properties,
		{ time = resolved.time, style = Enum.EasingStyle.Back, direction = Enum.EasingDirection.Out }
	)
end

function Motion.delay(seconds, callback)
	task.delay(seconds, callback)
end

return Motion
