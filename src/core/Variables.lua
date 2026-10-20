local Services = {
	Players = game:GetService("Players"),
	UserInputService = game:GetService("UserInputService"),
	RunService = game:GetService("RunService"),
	TweenService = game:GetService("TweenService"),
	TextService = game:GetService("TextService"),
	HttpService = game:GetService("HttpService"),
	GuiService = game:GetService("GuiService"),
	ContentProvider = game:GetService("ContentProvider"),
	LocalizationService = game:GetService("LocalizationService"),
	Clipboard = nil,
}

local Variables = {
	services = Services,
	container = nil,
	displayOrder = 100,
	screenGui = nil,
	activeInput = nil,
	renderScale = 1,
}

function Variables.setContainer(container)
	Variables.container = container
end

function Variables.getContainer()
	if Variables.container then
		return Variables.container
	end
	local player = Services.Players.LocalPlayer
	if player then
		return player:WaitForChild("PlayerGui")
	end
	return Services.GuiService
end

function Variables.isStudio()
	return Services.RunService:IsStudio()
end

function Variables.hasWrite()
	return type(writefile) == "function"
end

function Variables.hasRead()
	return type(readfile) == "function"
end

function Variables.hasIsFile()
	return type(isfile) == "function"
end

function Variables.hasMakeDir()
	return type(makedir) == "function"
end

function Variables.hasClipboard()
	return type(setclipboard) == "function"
end

function Variables.hasGetAsset()
	return type(getasset) == "function"
end

function Variables.getClipboard()
	if type(getclipboard) == "function" then
		return getclipboard()
	end
	return nil
end

function Variables.setClipboard(value)
	if type(setclipboard) == "function" then
		setclipboard(value)
		return true
	end
	return false
end

function Variables.isExploit()
	return type(request) == "function" or type(getgenv) == "function"
end

return Variables
