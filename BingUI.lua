local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local MONTSERRAT = "rbxasset://fonts/families/Montserrat.json"

local Icons = {
	ChevronDown = "rbxassetid://134243273101015",
	Check = "rbxassetid://93898873302694",
	Keyboard = "rbxassetid://121474456068237",
}

local Library = {
	Flags = {},
	Elements = {},
	Icons = Icons,
	AssetFolder = "BingUI",
	Theme = {
		Background = Color3.fromRGB(14, 16, 26),
		Transparency = 0.12,
		Stroke = Color3.fromRGB(62, 68, 110),
		Divider = Color3.fromRGB(46, 51, 80),
		Title = Color3.fromRGB(130, 150, 255),
		Text = Color3.fromRGB(236, 238, 250),
		SubText = Color3.fromRGB(150, 160, 205),
		Button = Color3.fromRGB(32, 38, 68),
		ButtonHover = Color3.fromRGB(44, 52, 92),
		Accent = Color3.fromRGB(100, 116, 255),
		Element = Color3.fromRGB(27, 32, 56),
		ElementLight = Color3.fromRGB(40, 47, 82),
		Font = Font.new(MONTSERRAT, Enum.FontWeight.Medium),
		BoldFont = Font.new(MONTSERRAT, Enum.FontWeight.Bold),
		TitleFont = Font.new(MONTSERRAT, Enum.FontWeight.Heavy),
	},
}

local SIDEBAR_WIDTH = 176
local ROW_HEIGHT = 34
local BOX_SIZE = 30
local KNOB_WIDTH = 14
local SECTION_HEADER = 36

local imageCache = {}

local function resolveImage(image, apply)
	if type(image) == "number" then
		image = "rbxassetid://" .. image
	end
	if type(image) ~= "string" or not string.match(image, "^https?://") then
		apply(image or "")
		return
	end
	if imageCache[image] then
		apply(imageCache[image])
		return
	end
	if not (writefile and getcustomasset) then
		warn("[BingUI] writefile / getcustomasset are not available, cannot load " .. image)
		apply("")
		return
	end
	task.spawn(function()
		local ok, result = pcall(function()
			local folder = Library.AssetFolder
			if makefolder and not (isfolder and isfolder(folder)) then
				makefolder(folder)
			end
			local name = string.sub((string.gsub(image, "[^%w]", "_")), -80)
			if not string.match(name, "_png$") and not string.match(name, "_jpg$") then
				name ..= "_png"
			end
			local path = folder .. "/" .. name .. ".png"
			if not (isfile and isfile(path)) then
				writefile(path, game:HttpGet(image))
			end
			return getcustomasset(path)
		end)
		if ok and result then
			imageCache[image] = result
			apply(result)
		else
			warn("[BingUI] failed to load image " .. image .. ": " .. tostring(result))
			apply("")
		end
	end)
end

Library.ResolveImage = resolveImage

local function create(className, props, children)
	local inst = Instance.new(className)
	local parent
	for key, value in pairs(props or {}) do
		if key == "Parent" then
			parent = value
		else
			inst[key] = value
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function corner(radius)
	return create("UICorner", { CornerRadius = UDim.new(0, radius or 6) })
end

local function tween(inst, props, duration, style)
	local info = TweenInfo.new(duration or 0.15, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local t = TweenService:Create(inst, info, props)
	t:Play()
	return t
end

local function isClick(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

local function isMove(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch
end

local function normalize(options, key)
	if type(options) == "string" then
		return { [key or "Name"] = options }
	end
	return options or {}
end

local function keyName(key)
	if type(key) == "string" then
		return key
	elseif key then
		return key.Name
	end
	return "None"
end

local function toKeyCode(name)
	if name == "None" then
		return nil
	end
	local ok, code = pcall(function()
		return Enum.KeyCode[name]
	end)
	return ok and code or nil
end

local function register(element)
	if element.Flag then
		Library.Flags[element.Flag] = element.Value
		Library.Elements[element.Flag] = element
	end
end

local function setFlag(element)
	if element.Flag then
		Library.Flags[element.Flag] = element.Value
	end
end

local function label(theme, props)
	local base = {
		BackgroundTransparency = 1,
		FontFace = theme.Font,
		TextColor3 = theme.Text,
		TextSize = 17,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}
	for key, value in pairs(props) do
		base[key] = value
	end
	return create("TextLabel", base)
end

local function icon(image, color, props)
	local base = {
		BackgroundTransparency = 1,
		Image = image,
		ImageColor3 = color,
		ScaleType = Enum.ScaleType.Fit,
	}
	for key, value in pairs(props) do
		base[key] = value
	end
	return create("ImageLabel", base)
end

local function hoverColor(button, normal, hovered, isLocked)
	button.MouseEnter:Connect(function()
		if not (isLocked and isLocked()) then
			tween(button, { BackgroundColor3 = hovered })
		end
	end)
	button.MouseLeave:Connect(function()
		if not (isLocked and isLocked()) then
			tween(button, { BackgroundColor3 = normal })
		end
	end)
end

local function makeDraggable(window, handle, target)
	local state = { Moved = false }
	local dragging, dragStart, startPos = false, nil, nil

	handle.InputBegan:Connect(function(input)
		if not isClick(input) then
			return
		end
		dragging, state.Moved = true, false
		dragStart, startPos = input.Position, target.Position
	end)

	window:_track(UserInputService.InputChanged:Connect(function(input)
		if not dragging or not isMove(input) then
			return
		end
		local delta = input.Position - dragStart
		if delta.Magnitude > 4 then
			state.Moved = true
		end
		target.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end))

	window:_track(UserInputService.InputEnded:Connect(function(input)
		if isClick(input) then
			dragging = false
		end
	end))

	return state
end

local function buildToggle(theme, parent, options, order, textSize)
	local toggle = {
		Type = "Toggle",
		Flag = options.Flag,
		Value = options.Default == true,
	}

	local row = create("TextButton", {
		Name = "Toggle",
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
		LayoutOrder = order,
		Parent = parent,
	})
	local box = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(BOX_SIZE, BOX_SIZE),
		BackgroundColor3 = theme.Element,
		Parent = row,
	}, { corner(7) })
	local check = icon(Icons.Check, theme.Accent, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(BOX_SIZE - 8, BOX_SIZE - 8),
		Parent = box,
	})
	local checkScale = create("UIScale", { Scale = 0, Parent = check })
	local text = label(theme, {
		Position = UDim2.new(0, BOX_SIZE + 10, 0, 0),
		Size = UDim2.new(1, -(BOX_SIZE + 10), 1, 0),
		Text = options.Name or "Toggle",
		TextSize = textSize or 17,
		Parent = row,
	})

	function toggle:Set(value, silent)
		value = value == true
		local changed = value ~= self.Value
		self.Value = value
		setFlag(self)
		tween(checkScale, { Scale = value and 1 or 0 }, 0.18, Enum.EasingStyle.Back)
		if changed and not silent and options.Callback then
			task.spawn(options.Callback, value)
		end
	end

	function toggle:Get()
		return self.Value
	end

	function toggle:SetText(newText)
		text.Text = newText
	end

	row.MouseButton1Click:Connect(function()
		toggle:Set(not toggle.Value)
	end)
	row.MouseEnter:Connect(function()
		tween(box, { BackgroundColor3 = theme.ElementLight })
	end)
	row.MouseLeave:Connect(function()
		tween(box, { BackgroundColor3 = theme.Element })
	end)

	checkScale.Scale = toggle.Value and 1 or 0
	toggle.Instance = row
	register(toggle)
	return toggle
end

local function buildButton(theme, parent, options, order, size)
	local btn = create("TextButton", {
		Name = "Button",
		AutoButtonColor = false,
		BackgroundColor3 = theme.Button,
		Size = size or UDim2.new(1, 0, 0, 42),
		FontFace = theme.Font,
		Text = options.Name or "Button",
		TextColor3 = theme.Text,
		TextSize = 17,
		TextTruncate = Enum.TextTruncate.AtEnd,
		LayoutOrder = order or 0,
		Parent = parent,
	}, { corner(8) })

	hoverColor(btn, theme.Button, theme.ButtonHover)
	btn.MouseButton1Click:Connect(function()
		btn.BackgroundColor3 = theme.Accent
		tween(btn, { BackgroundColor3 = theme.Button }, 0.35)
		if options.Callback then
			task.spawn(options.Callback)
		end
	end)

	local button = { Type = "Button", Instance = btn }
	function button:SetText(newText)
		btn.Text = newText
	end
	return button
end

local Container = {}
Container.__index = Container

function Container:_next()
	self._order += 1
	return self._order
end

function Container:AddToggle(options)
	return buildToggle(self.Window.Theme, self.Frame, normalize(options), self:_next())
end

function Container:AddToggleGrid(options)
	options = options or {}
	local columns = options.Columns or 4
	local padding = 10

	local frame = create("Frame", {
		Name = "ToggleGrid",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = self:_next(),
		Parent = self.Frame,
	}, {
		create("UIGridLayout", {
			CellPadding = UDim2.fromOffset(padding, 12),
			CellSize = UDim2.new(1 / columns, -padding * (columns - 1) / columns, 0, ROW_HEIGHT),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	local theme = self.Window.Theme
	local grid = { Instance = frame, _order = 0 }
	function grid:AddToggle(toggleOptions)
		self._order += 1
		return buildToggle(theme, frame, normalize(toggleOptions), self._order, 16)
	end
	return grid
end

function Container:AddSlider(options)
	options = normalize(options)
	local theme = self.Window.Theme
	local page = self.Page
	local min, max = options.Min or 0, options.Max or 100
	local decimals = options.Decimals or 0
	local increment = options.Increment or 10 ^ -decimals

	local slider = { Type = "Slider", Flag = options.Flag, Value = nil }

	local row = create("Frame", {
		Name = "Slider",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 38),
		LayoutOrder = self:_next(),
		Parent = self.Frame,
	})
	local bar = create("TextButton", {
		AutoButtonColor = false,
		Text = "",
		BackgroundColor3 = theme.Element,
		Size = UDim2.new(0.62, 0, 1, 0),
		ClipsDescendants = true,
		Parent = row,
	}, { corner(6) })
	local fill = create("Frame", {
		BackgroundColor3 = theme.ElementLight,
		BorderSizePixel = 0,
		Size = UDim2.new(0, KNOB_WIDTH, 1, 0),
		Parent = bar,
	}, { corner(6) })
	local knob = create("Frame", {
		BackgroundColor3 = theme.Accent,
		BorderSizePixel = 0,
		Size = UDim2.new(0, KNOB_WIDTH, 1, 0),
		Parent = bar,
	}, { corner(4) })
	local valueText = label(theme, {
		Size = UDim2.fromScale(1, 1),
		FontFace = theme.BoldFont,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 2,
		Parent = bar,
	})
	local nameText = label(theme, {
		Position = UDim2.new(0.62, 12, 0, 0),
		Size = UDim2.new(0.38, -12, 1, 0),
		Text = options.Name or "Slider",
		Parent = row,
	})

	local function format(value)
		return string.format("%." .. decimals .. "f", value) .. (options.Suffix or "")
	end

	function slider:Set(value, silent)
		value = tonumber(value) or min
		value = min + math.floor((value - min) / increment + 0.5) * increment
		value = math.clamp(tonumber(string.format("%." .. decimals .. "f", value)) or min, min, max)

		local changed = value ~= self.Value
		self.Value = value
		setFlag(self)

		local p = max > min and (value - min) / (max - min) or 0
		tween(knob, { Position = UDim2.new(p, -p * KNOB_WIDTH, 0, 0) }, 0.08)
		tween(fill, { Size = UDim2.new(p, KNOB_WIDTH - p * KNOB_WIDTH, 1, 0) }, 0.08)
		valueText.Text = format(value)

		if changed and not silent and options.Callback then
			task.spawn(options.Callback, value)
		end
	end

	function slider:Get()
		return self.Value
	end

	function slider:SetText(newText)
		nameText.Text = newText
	end

	local dragging = false
	local function setFromX(x)
		local width = bar.AbsoluteSize.X
		if width <= 0 then
			return
		end
		local p = math.clamp((x - bar.AbsolutePosition.X) / width, 0, 1)
		slider:Set(min + (max - min) * p)
	end

	bar.InputBegan:Connect(function(input)
		if isClick(input) then
			dragging = true
			page.ScrollingEnabled = false
			setFromX(input.Position.X)
		end
	end)
	self.Window:_track(UserInputService.InputChanged:Connect(function(input)
		if dragging and isMove(input) then
			setFromX(input.Position.X)
		end
	end))
	self.Window:_track(UserInputService.InputEnded:Connect(function(input)
		if dragging and isClick(input) then
			dragging = false
			page.ScrollingEnabled = true
		end
	end))

	slider:Set(options.Default or min, true)
	slider.Instance = row
	register(slider)
	return slider
end

function Container:AddKeybind(options)
	options = normalize(options)
	local theme = self.Window.Theme
	local window = self.Window

	local keybind = {
		Type = "Keybind",
		Flag = options.Flag,
		Value = keyName(options.Default),
		Listening = false,
	}

	local row = create("Frame", {
		Name = "Keybind",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 38),
		LayoutOrder = self:_next(),
		Parent = self.Frame,
	})
	local box = create("TextButton", {
		AutoButtonColor = false,
		Text = "",
		BackgroundColor3 = theme.Element,
		Size = UDim2.new(0.62, 0, 1, 0),
		Parent = row,
	}, { corner(6) })
	local stroke = create("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = theme.Accent,
		Thickness = 1.5,
		Transparency = 1,
		Parent = box,
	})
	icon(Icons.Keyboard, theme.SubText, {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.5, 0),
		Size = UDim2.fromOffset(20, 20),
		Parent = box,
	})
	local keyText = label(theme, {
		Size = UDim2.fromScale(1, 1),
		FontFace = theme.BoldFont,
		TextSize = 17,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = box,
	})
	local nameText = label(theme, {
		Position = UDim2.new(0.62, 12, 0, 0),
		Size = UDim2.new(0.38, -12, 1, 0),
		Text = options.Name or "Keybind",
		Parent = row,
	})

	local function refresh()
		if keybind.Listening then
			keyText.Text = "..."
			keyText.TextColor3 = theme.Accent
			tween(stroke, { Transparency = 0 })
		else
			keyText.Text = keybind.Value
			keyText.TextColor3 = theme.Text
			tween(stroke, { Transparency = 1 })
		end
	end

	function keybind:Set(value, silent)
		local name = keyName(value)
		if name ~= "None" and not toKeyCode(name) then
			return
		end
		local changed = name ~= self.Value
		self.Value = name
		setFlag(self)
		refresh()
		if changed and not silent and options.ChangedCallback then
			task.spawn(options.ChangedCallback, toKeyCode(name))
		end
	end

	function keybind:Get()
		return toKeyCode(self.Value)
	end

	function keybind:SetText(newText)
		nameText.Text = newText
	end

	box.MouseButton1Click:Connect(function()
		keybind.Listening = not keybind.Listening
		window._binding = keybind.Listening
		refresh()
	end)
	box.MouseEnter:Connect(function()
		tween(box, { BackgroundColor3 = theme.ElementLight })
	end)
	box.MouseLeave:Connect(function()
		tween(box, { BackgroundColor3 = theme.Element })
	end)

	local holding = false
	window:_track(UserInputService.InputBegan:Connect(function(input, processed)
		if input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end
		if keybind.Listening then
			keybind.Listening = false
			task.defer(function()
				window._binding = false
			end)
			if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
				keybind:Set("None")
			else
				keybind:Set(input.KeyCode)
			end
			refresh()
			return
		end
		if processed or keybind.Value == "None" or input.KeyCode.Name ~= keybind.Value then
			return
		end
		if options.Mode == "Hold" then
			holding = true
			if options.Callback then
				task.spawn(options.Callback, true)
			end
		elseif options.Callback then
			task.spawn(options.Callback)
		end
	end))
	window:_track(UserInputService.InputEnded:Connect(function(input)
		if holding and input.KeyCode.Name == keybind.Value then
			holding = false
			if options.Callback then
				task.spawn(options.Callback, false)
			end
		end
	end))

	refresh()
	keybind.Instance = row
	register(keybind)
	return keybind
end

function Container:AddButton(options)
	return buildButton(self.Window.Theme, self.Frame, normalize(options), self:_next())
end

function Container:AddButtons(list)
	local theme = self.Window.Theme
	local count = math.max(#list, 1)
	local gap = 12

	local row = create("Frame", {
		Name = "ButtonRow",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 42),
		LayoutOrder = self:_next(),
		Parent = self.Frame,
	}, {
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, gap),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	local buttons = {}
	local size = UDim2.new(1 / count, -gap * (count - 1) / count, 1, 0)
	for i, buttonOptions in ipairs(list) do
		buttons[i] = buildButton(theme, row, normalize(buttonOptions), i, size)
	end
	return buttons
end

function Container:AddLabel(options)
	options = normalize(options, "Text")
	local theme = self.Window.Theme

	local text = label(theme, {
		Name = "Label",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = options.Text or "",
		TextColor3 = options.Color or theme.Text,
		TextSize = options.TextSize or 17,
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.None,
		RichText = true,
		TextXAlignment = options.Center and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
		LayoutOrder = self:_next(),
		Parent = self.Frame,
	})

	local element = { Type = "Label", Instance = text }
	function element:Set(newText)
		text.Text = newText
	end
	return element
end

function Container:AddRadio(options)
	options = normalize(options)
	local theme = self.Window.Theme
	local choices = options.Options or {}

	local radio = {
		Type = "Radio",
		Flag = options.Flag,
		Value = options.Default or choices[1],
	}

	local holder = create("Frame", {
		Name = "Radio",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = self:_next(),
		Parent = self.Frame,
	}, {
		create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
	})

	if options.Name then
		label(theme, {
			Size = UDim2.new(1, 0, 0, 22),
			Text = options.Name,
			LayoutOrder = 1,
			Parent = holder,
		})
	end

	local listLayout = create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 18),
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	pcall(function()
		listLayout.Wraps = true
	end)
	local list = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 2,
		Parent = holder,
	}, { listLayout })

	local dots = {}
	for i, choice in ipairs(choices) do
		local button = create("TextButton", {
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Text = "",
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 0, 32),
			LayoutOrder = i,
			Parent = list,
		}, {
			create("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 8),
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		})
		local circle = create("Frame", {
			Size = UDim2.fromOffset(28, 28),
			BackgroundColor3 = theme.Element,
			LayoutOrder = 1,
			Parent = button,
		}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		dots[choice] = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(0, 0),
			BackgroundColor3 = theme.Accent,
			Parent = circle,
		}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		label(theme, {
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 0, 28),
			Text = tostring(choice),
			TextTruncate = Enum.TextTruncate.None,
			LayoutOrder = 2,
			Parent = button,
		})

		button.MouseButton1Click:Connect(function()
			radio:Set(choice)
		end)
	end

	function radio:Set(value, silent)
		if dots[value] == nil then
			return
		end
		local changed = value ~= self.Value
		self.Value = value
		setFlag(self)
		for choice, dot in pairs(dots) do
			local size = choice == value and 18 or 0
			tween(dot, { Size = UDim2.fromOffset(size, size) }, 0.2, Enum.EasingStyle.Back)
		end
		if changed and not silent and options.Callback then
			task.spawn(options.Callback, value)
		end
	end

	function radio:Get()
		return self.Value
	end

	radio:Set(radio.Value, true)
	radio.Instance = holder
	register(radio)
	return radio
end

function Container:AddSection(options)
	options = normalize(options)
	local theme = self.Window.Theme

	local wrapper = create("Frame", {
		Name = "Section",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = self:_next(),
		Parent = self.Frame,
	}, {
		create("UIListLayout", { Padding = UDim.new(0, 0), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	local header = create("TextButton", {
		AutoButtonColor = false,
		Text = "",
		BackgroundColor3 = theme.Element,
		Size = UDim2.new(1, 0, 0, SECTION_HEADER),
		LayoutOrder = 1,
		Parent = wrapper,
	}, { corner(7) })
	local arrow = icon(Icons.ChevronDown, theme.Text, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 22, 0.5, 0),
		Size = UDim2.fromOffset(20, 20),
		Parent = header,
	})
	label(theme, {
		Position = UDim2.new(0, 42, 0, 0),
		Size = UDim2.new(1, -50, 1, 0),
		FontFace = theme.BoldFont,
		Text = options.Name or "Section",
		Parent = header,
	})

	local clip = create("Frame", {
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Size = UDim2.new(1, 0, 0, 0),
		LayoutOrder = 2,
		Parent = wrapper,
	})
	local body = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = clip,
	}, {
		create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
		create("UIPadding", {
			PaddingTop = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 4),
		}),
	})

	local section = setmetatable({
		Window = self.Window,
		Page = self.Page,
		Frame = body,
		Instance = wrapper,
		Open = options.Collapsed ~= true,
		_order = 0,
	}, Container)

	local function unscaled(pixels)
		local h = header.AbsoluteSize.Y
		local ratio = h > 0 and h / SECTION_HEADER or 1
		return pixels / ratio
	end

	local animation = 0
	function section:SetOpen(open, instant)
		self.Open = open
		animation += 1
		local id = animation

		tween(arrow, { Rotation = open and 0 or -90 }, 0.25)
		tween(header, { BackgroundColor3 = open and theme.Accent or theme.Element }, 0.25)

		local target = open and unscaled(body.AbsoluteSize.Y) or 0
		local current = unscaled(clip.AbsoluteSize.Y)
		clip.AutomaticSize = Enum.AutomaticSize.None
		if instant then
			clip.Size = UDim2.new(1, 0, 0, target)
		else
			clip.Size = UDim2.new(1, 0, 0, current)
			tween(clip, { Size = UDim2.new(1, 0, 0, target) }, 0.3, Enum.EasingStyle.Quint)
		end

		if open then
			task.delay(instant and 0 or 0.31, function()
				if animation == id and section.Open then
					clip.AutomaticSize = Enum.AutomaticSize.Y
					clip.Size = UDim2.new(1, 0, 0, 0)
				end
			end)
		end
	end

	header.MouseButton1Click:Connect(function()
		section:SetOpen(not section.Open)
	end)
	header.MouseEnter:Connect(function()
		if not section.Open then
			tween(header, { BackgroundColor3 = theme.ElementLight })
		end
	end)
	header.MouseLeave:Connect(function()
		if not section.Open then
			tween(header, { BackgroundColor3 = theme.Element })
		end
	end)

	arrow.Rotation = section.Open and 0 or -90
	header.BackgroundColor3 = section.Open and theme.Accent or theme.Element
	if section.Open then
		clip.AutomaticSize = Enum.AutomaticSize.Y
	end
	return section
end

function Container:AddDropdown(options)
	options = normalize(options)
	local theme = self.Window.Theme
	local multi = options.Multi == true
	local values = options.Values or options.Options or {}
	local optionHeight, maxVisible = 30, options.MaxVisible or 6

	local dropdown = { Type = "Dropdown", Flag = options.Flag, Open = false, Values = values }
	if multi then
		dropdown.Value = table.clone(type(options.Default) == "table" and options.Default or {})
	else
		dropdown.Value = options.Default or values[1]
	end

	local holder = create("Frame", {
		Name = "Dropdown",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = self:_next(),
		Parent = self.Frame,
	}, {
		create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	local row = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 38),
		LayoutOrder = 1,
		Parent = holder,
	})
	local box = create("TextButton", {
		AutoButtonColor = false,
		Text = "",
		BackgroundColor3 = theme.Element,
		Size = UDim2.new(0.62, 0, 1, 0),
		Parent = row,
	}, { corner(6) })
	local valueText = label(theme, {
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -44, 1, 0),
		Parent = box,
	})
	local arrow = icon(Icons.ChevronDown, theme.SubText, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(18, 18),
		Rotation = -90,
		Parent = box,
	})
	local nameText = label(theme, {
		Position = UDim2.new(0.62, 12, 0, 0),
		Size = UDim2.new(0.38, -12, 1, 0),
		Text = options.Name or "Dropdown",
		Parent = row,
	})

	local clip = create("Frame", {
		BackgroundColor3 = theme.Element,
		ClipsDescendants = true,
		Size = UDim2.new(0.62, 0, 0, 0),
		Visible = false,
		LayoutOrder = 2,
		Parent = holder,
	}, { corner(6) })
	local list = create("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = theme.Accent,
		Parent = clip,
	}, {
		create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }),
		create("UIPadding", {
			PaddingTop = UDim.new(0, 4),
			PaddingBottom = UDim.new(0, 4),
			PaddingLeft = UDim.new(0, 4),
			PaddingRight = UDim.new(0, 4),
		}),
	})

	local items = {}

	local function isSelected(value)
		if multi then
			return table.find(dropdown.Value, value) ~= nil
		end
		return dropdown.Value == value
	end

	local function refresh()
		if multi then
			valueText.Text = #dropdown.Value > 0 and table.concat(dropdown.Value, ", ") or "None"
		else
			valueText.Text = dropdown.Value ~= nil and tostring(dropdown.Value) or "None"
		end
		for value, item in pairs(items) do
			local selected = isSelected(value)
			tween(item.Button, { BackgroundTransparency = selected and 0 or 1 }, 0.15)
			item.Text.TextColor3 = selected and theme.Text or theme.SubText
			if item.Check then
				tween(item.Check, { ImageTransparency = selected and 0 or 1 }, 0.15)
			end
		end
	end

	local function listHeight()
		local count = math.min(#dropdown.Values, maxVisible)
		return count * optionHeight + math.max(count - 1, 0) * 2 + 8
	end

	local function choose(value)
		if multi then
			local current = table.clone(dropdown.Value)
			local index = table.find(current, value)
			if index then
				table.remove(current, index)
			else
				table.insert(current, value)
			end
			dropdown:Set(current)
		else
			dropdown:Set(value)
			dropdown:SetOpen(false)
		end
	end

	local function build()
		for _, item in pairs(items) do
			item.Button:Destroy()
		end
		table.clear(items)
		for i, value in ipairs(dropdown.Values) do
			local button = create("TextButton", {
				AutoButtonColor = false,
				Text = "",
				BackgroundColor3 = theme.ElementLight,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, optionHeight),
				LayoutOrder = i,
				Parent = list,
			}, { corner(5) })
			local text = label(theme, {
				Position = UDim2.fromOffset(10, 0),
				Size = UDim2.new(1, multi and -40 or -20, 1, 0),
				Text = tostring(value),
				TextSize = 16,
				TextColor3 = theme.SubText,
				Parent = button,
			})
			local check
			if multi then
				check = icon(Icons.Check, theme.Accent, {
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -8, 0.5, 0),
					Size = UDim2.fromOffset(16, 16),
					ImageTransparency = 1,
					Parent = button,
				})
			end
			button.MouseButton1Click:Connect(function()
				choose(value)
			end)
			items[value] = { Button = button, Text = text, Check = check }
		end
		refresh()
	end

	local anim = 0
	function dropdown:SetOpen(open)
		self.Open = open
		anim += 1
		local id = anim
		tween(arrow, { Rotation = open and 0 or -90 }, 0.25)
		tween(box, { BackgroundColor3 = open and theme.ElementLight or theme.Element }, 0.2)
		if open then
			clip.Visible = true
		end
		tween(clip, { Size = UDim2.new(0.62, 0, 0, open and listHeight() or 0) }, 0.28, Enum.EasingStyle.Quint)
			.Completed:Connect(function()
				if anim == id and not dropdown.Open then
					clip.Visible = false
				end
			end)
	end

	function dropdown:Set(value, silent)
		if multi then
			local clean = {}
			for _, v in ipairs(type(value) == "table" and value or { value }) do
				if table.find(self.Values, v) and not table.find(clean, v) then
					table.insert(clean, v)
				end
			end
			self.Value = clean
		else
			if not table.find(self.Values, value) then
				return
			end
			if value == self.Value then
				return
			end
			self.Value = value
		end
		setFlag(self)
		refresh()
		if not silent and options.Callback then
			task.spawn(options.Callback, self.Value)
		end
	end

	function dropdown:Get()
		return self.Value
	end

	function dropdown:SetValues(newValues)
		self.Values = newValues
		if multi then
			self:Set(self.Value, true)
		elseif not table.find(newValues, self.Value) then
			self.Value = newValues[1]
			setFlag(self)
		end
		build()
		if self.Open then
			tween(clip, { Size = UDim2.new(0.62, 0, 0, listHeight()) }, 0.2)
		end
	end

	function dropdown:SetText(newText)
		nameText.Text = newText
	end

	box.MouseButton1Click:Connect(function()
		dropdown:SetOpen(not dropdown.Open)
	end)
	box.MouseEnter:Connect(function()
		if not dropdown.Open then
			tween(box, { BackgroundColor3 = theme.ElementLight })
		end
	end)
	box.MouseLeave:Connect(function()
		if not dropdown.Open then
			tween(box, { BackgroundColor3 = theme.Element })
		end
	end)

	build()
	dropdown.Instance = holder
	register(dropdown)
	return dropdown
end

function Container:AddImage(options)
	options = normalize(options, "Image")
	local theme = self.Window.Theme
	local image = create("ImageLabel", {
		Name = "Image",
		BackgroundColor3 = theme.Element,
		BackgroundTransparency = options.Background == false and 1 or 0,
		Image = "",
		ScaleType = options.ScaleType or Enum.ScaleType.Fit,
		Size = UDim2.new(1, 0, 0, options.Height or 160),
		LayoutOrder = self:_next(),
		Parent = self.Frame,
	}, { corner(8) })

	local element = { Type = "Image", Instance = image }
	function element:Set(newImage)
		resolveImage(newImage, function(asset)
			image.Image = asset
		end)
	end
	element:Set(options.Image)
	return element
end

function Container:AddImagePicker(options)
	options = normalize(options)
	local theme = self.Window.Theme
	local columns = options.Columns or 4
	local gap = 10
	local cardHeight = options.CardHeight or 110

	local picker = { Type = "ImagePicker", Flag = options.Flag, Value = options.Default, Entries = {} }

	local frame
	if options.Height then
		frame = create("ScrollingFrame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, options.Height),
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = theme.Accent,
			LayoutOrder = self:_next(),
			Parent = self.Frame,
		})
	else
		frame = create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = self:_next(),
			Parent = self.Frame,
		})
	end
	frame.Name = "ImagePicker"
	create("UIGridLayout", {
		CellPadding = UDim2.fromOffset(gap, gap),
		CellSize = UDim2.new(1 / columns, -gap * (columns - 1) / columns - (options.Height and 2 or 0), 0, cardHeight),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = frame,
	})
	create("UIPadding", { PaddingTop = UDim.new(0, 2), PaddingLeft = UDim.new(0, 1), Parent = frame })

	local cards = {}

	local function refresh()
		for name, card in pairs(cards) do
			local selected = name == picker.Value
			tween(card.Stroke, { Transparency = selected and 0 or 1 }, 0.15)
			card.Text.TextColor3 = selected and theme.Text or theme.SubText
		end
	end

	function picker:Set(name, silent)
		local entry = self.Entries[name]
		if not entry then
			return
		end
		local changed = name ~= self.Value
		self.Value = name
		setFlag(self)
		refresh()
		if changed and not silent then
			if entry.callback then
				task.spawn(entry.callback)
			end
			if options.Callback then
				task.spawn(options.Callback, name)
			end
		end
	end

	function picker:Get()
		return self.Value
	end

	function picker:Add(entry)
		local name = entry.name or entry.Name
		local image = entry.image or entry.Image or entry.Asset or ""
		self.Entries[name] = entry

		local card = create("TextButton", {
			AutoButtonColor = false,
			Text = "",
			BackgroundColor3 = theme.Element,
			LayoutOrder = #frame:GetChildren(),
			Parent = frame,
		}, { corner(8) })
		local stroke = create("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = theme.Accent,
			Thickness = 2,
			Transparency = 1,
			Parent = card,
		})
		local picture = create("ImageLabel", {
			BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Crop,
			Position = UDim2.fromOffset(4, 4),
			Size = UDim2.new(1, -8, 1, -30),
			Parent = card,
		}, { corner(6) })
		resolveImage(image, function(asset)
			picture.Image = asset
		end)
		local text = label(theme, {
			Position = UDim2.new(0, 6, 1, -26),
			Size = UDim2.new(1, -12, 0, 24),
			Text = name,
			TextSize = 14,
			TextColor3 = theme.SubText,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = card,
		})

		card.MouseButton1Click:Connect(function()
			picker:Set(name)
		end)
		card.MouseEnter:Connect(function()
			tween(card, { BackgroundColor3 = theme.ElementLight })
		end)
		card.MouseLeave:Connect(function()
			tween(card, { BackgroundColor3 = theme.Element })
		end)

		cards[name] = { Stroke = stroke, Text = text }
		refresh()
		return card
	end

	for _, entry in ipairs(options.Values or {}) do
		picker:Add(entry)
	end

	picker.Instance = frame
	register(picker)
	return picker
end

local Window = {}
Window.__index = Window

function Window:_track(connection)
	table.insert(self.Connections, connection)
	return connection
end

function Library:CreateWindow(options)
	options = normalize(options, "Title")

	local theme = table.clone(self.Theme)
	for key, value in pairs(options.Theme or {}) do
		theme[key] = value
	end

	local window = setmetatable({
		Theme = theme,
		Tabs = {},
		Connections = {},
		Visible = false,
		ToggleKey = options.ToggleKey or Enum.KeyCode.RightShift,
		_anim = 0,
		_ready = false,
		_binding = false,
	}, Window)

	local size = options.Size or UDim2.fromOffset(720, 565)
	local width, height = size.X.Offset, size.Y.Offset

	local gui = create("ScreenGui", {
		Name = options.Name or "BingUI",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 100,
		Parent = options.Parent or Players.LocalPlayer:WaitForChild("PlayerGui"),
	})

	local scaleValue = options.Scale
	if not scaleValue then
		local camera = workspace.CurrentCamera
		local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
		scaleValue = math.min(1, viewport.X * 0.92 / width, viewport.Y * 0.92 / height)
	end

	local main = create("CanvasGroup", {
		Name = "Main",
		Position = UDim2.new(0.5, -width * scaleValue / 2, 0.5, -height * scaleValue / 2),
		Size = UDim2.fromOffset(width, height),
		BackgroundColor3 = theme.Background,
		BackgroundTransparency = theme.Transparency,
		GroupTransparency = 1,
		Parent = gui,
	}, {
		corner(12),
	})
	local mainStroke = create("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = theme.Stroke,
		Thickness = 1,
		Transparency = 1,
		Parent = main,
	})
	local uiScale = create("UIScale", { Scale = scaleValue, Parent = main })

	local body = create("Frame", {
		Name = "Body",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(width, height),
		Parent = main,
	})

	local sidebar = create("Frame", {
		Name = "Sidebar",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(16, 16),
		Size = UDim2.new(0, SIDEBAR_WIDTH, 1, -32),
		Parent = body,
	})
	local title = create("Frame", {
		Name = "Title",
		BackgroundTransparency = 1,
		Active = true,
		Size = UDim2.new(1, 0, 0, 80),
		Parent = sidebar,
	}, {
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	local titleText = options.Title or "Bing"
	local logoFirst = label(theme, {
		Name = "First",
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 62),
		FontFace = theme.TitleFont,
		Text = string.sub(titleText, 1, 1),
		TextColor3 = theme.Title,
		TextSize = 58,
		TextTruncate = Enum.TextTruncate.None,
		LayoutOrder = 1,
		Parent = title,
	})
	local logoRest = label(theme, {
		Name = "Rest",
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 62),
		FontFace = theme.TitleFont,
		Text = string.sub(titleText, 2),
		TextColor3 = theme.Title,
		TextSize = 58,
		TextTruncate = Enum.TextTruncate.None,
		LayoutOrder = 2,
		Parent = title,
	})
	create("Frame", {
		BackgroundColor3 = theme.Divider,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 96),
		Size = UDim2.new(1, 0, 0, 1),
		Parent = sidebar,
	})
	local tabList = create("ScrollingFrame", {
		Name = "Tabs",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 116),
		Size = UDim2.new(1, 0, 1, -116),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 0,
		Parent = sidebar,
	}, {
		create("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }),
	})

	create("Frame", {
		Name = "Separator",
		BackgroundColor3 = theme.Divider,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(SIDEBAR_WIDTH + 32, 16),
		Size = UDim2.new(0, 1, 1, -32),
		Parent = body,
	})

	local content = create("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(SIDEBAR_WIDTH + 48, 12),
		Size = UDim2.new(1, -(SIDEBAR_WIDTH + 64), 1, -24),
		Parent = body,
	})
	local subtitle = label(theme, {
		Name = "Subtitle",
		Size = UDim2.new(1, 0, 0, 36),
		FontFace = theme.BoldFont,
		Text = options.Subtitle or "",
		TextSize = 20,
		RichText = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = content,
	})
	local pages = create("Frame", {
		Name = "Pages",
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Position = UDim2.fromOffset(0, 44),
		Size = UDim2.new(1, 0, 1, -44),
		Parent = content,
	})

	window.Gui = gui
	window.Main = main
	window.Body = body
	window._stroke = mainStroke
	window.Scale = uiScale
	window._scale = scaleValue
	window._size = Vector2.new(width, height)
	window._logoFirst = logoFirst
	window._logoRest = logoRest
	window._subtitle = subtitle
	window._tabList = tabList
	window._pages = pages

	local titleDrag = makeDraggable(window, title, main)
	makeDraggable(window, subtitle, main)
	title.InputEnded:Connect(function(input)
		if isClick(input) and not titleDrag.Moved then
			window:Toggle()
		end
	end)

	local barArea = create("TextButton", {
		Name = "HomeBar",
		AutoButtonColor = false,
		Visible = false,
		BackgroundTransparency = 1,
		Text = "",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, 0),
		Size = UDim2.fromOffset(240, 34),
		ZIndex = 5,
		Parent = gui,
	})
	local bar = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -8),
		Size = UDim2.fromOffset(134, 5),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 5,
		Parent = barArea,
	}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

	local swipeStart
	barArea.InputBegan:Connect(function(input)
		if isClick(input) then
			swipeStart = input.Position
		end
	end)
	window:_track(UserInputService.InputChanged:Connect(function(input)
		if swipeStart and isMove(input) and swipeStart.Y - input.Position.Y > 25 then
			swipeStart = nil
			window:SetVisible(true)
		end
	end))
	window:_track(UserInputService.InputEnded:Connect(function(input)
		if isClick(input) then
			swipeStart = nil
		end
	end))
	barArea.MouseButton1Click:Connect(function()
		window:SetVisible(true)
	end)
	barArea.MouseEnter:Connect(function()
		tween(bar, { Size = UDim2.fromOffset(150, 6) })
	end)
	barArea.MouseLeave:Connect(function()
		tween(bar, { Size = UDim2.fromOffset(134, 5) })
	end)

	window.HomeBar = barArea
	window._bar = bar
	window._barFade = 0

	local opener = options.Opener
	if opener == nil then
		opener = options.ToggleButton == false and "None" or "Floating"
	end
	window.Opener = opener

	window:_track(UserInputService.InputBegan:Connect(function(input, processed)
		if processed or window._binding or input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end
		if window.ToggleKey and input.KeyCode == window.ToggleKey then
			window:Toggle()
		end
	end))

	task.spawn(function()
		task.wait()
		if not gui.Parent then
			return
		end
		window:_measure()
		window:_applyCollapsed()
		window._ready = true
		if options.Visible == false then
			window:_finishClose(true)
		else
			main.GroupTransparency = 0
			mainStroke.Transparency = 0.3
			window:SetVisible(true)
		end
	end)

	return window
end

function Window:AddTab(name)
	local theme = self.Theme
	local window = self

	local button = create("TextButton", {
		Name = "Tab",
		AutoButtonColor = false,
		BackgroundColor3 = theme.Button,
		Size = UDim2.new(1, 0, 0, 46),
		FontFace = theme.Font,
		Text = name or "Tab",
		TextColor3 = theme.Text,
		TextSize = 17,
		TextTruncate = Enum.TextTruncate.AtEnd,
		LayoutOrder = #self.Tabs + 1,
		Parent = self._tabList,
	}, { corner(8) })

	local holder = create("CanvasGroup", {
		Name = "Page",
		Visible = false,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = self._pages,
	})
	local page = create("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = theme.Accent,
		Parent = holder,
	}, {
		create("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }),
		create("UIPadding", {
			PaddingTop = UDim.new(0, 2),
			PaddingBottom = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
		}),
	})

	local tab = setmetatable({
		Window = self,
		Name = name,
		Button = button,
		Holder = holder,
		Page = page,
		Frame = page,
		_order = 0,
	}, Container)

	hoverColor(button, theme.Button, theme.ButtonHover, function()
		return window.ActiveTab == tab
	end)
	button.MouseButton1Click:Connect(function()
		window:SelectTab(tab)
	end)

	table.insert(self.Tabs, tab)
	if not self.ActiveTab then
		self.ActiveTab = tab
		holder.Visible = true
		button.BackgroundColor3 = theme.Accent
	end
	return tab
end

function Window:SelectTab(target)
	if type(target) == "string" or type(target) == "number" then
		for index, tab in ipairs(self.Tabs) do
			if tab.Name == target or index == target then
				target = tab
				break
			end
		end
	end
	if type(target) ~= "table" or target == self.ActiveTab then
		return
	end

	self.ActiveTab = target
	for _, tab in ipairs(self.Tabs) do
		local active = tab == target
		tween(tab.Button, { BackgroundColor3 = active and self.Theme.Accent or self.Theme.Button }, 0.2)
		if active then
			tab.Holder.Visible = true
			tab.Holder.GroupTransparency = 1
			tab.Holder.Position = UDim2.fromOffset(0, 14)
			tween(tab.Holder, { GroupTransparency = 0, Position = UDim2.fromOffset(0, 0) }, 0.25, Enum.EasingStyle.Quint)
		else
			tab.Holder.Visible = false
		end
	end
end

function Window:_measure()
	local s = self.Scale.Scale
	local first = self._logoFirst
	local rel = (first.AbsolutePosition - self.Body.AbsolutePosition) / s
	local letter = first.AbsoluteSize / s
	if letter.X <= 0 or letter.Y <= 0 then
		rel = Vector2.new(16 + SIDEBAR_WIDTH / 2 - 60, 25)
		letter = Vector2.new(40, 62)
	end
	local side = math.max(letter.X, letter.Y * 0.8) + 16
	local center = rel + letter / 2
	self._boxPos = center - Vector2.new(side, side) / 2
	self._boxSize = Vector2.new(side, side)
end

function Window:_fullHome()
	local main = self.Main.Position
	local offset = self._boxPos * self._scale
	return UDim2.new(main.X.Scale, main.X.Offset - offset.X, main.Y.Scale, main.Y.Offset - offset.Y)
end

function Window:_collapsedGoal(home)
	local offset = self._boxPos * self._scale
	return {
		Position = UDim2.new(home.X.Scale, home.X.Offset + offset.X, home.Y.Scale, home.Y.Offset + offset.Y),
		Size = UDim2.fromOffset(self._boxSize.X, self._boxSize.Y),
	}, UDim2.fromOffset(-self._boxPos.X, -self._boxPos.Y)
end

function Window:_applyCollapsed()
	local goal, bodyPos = self:_collapsedGoal(self.Main.Position)
	self.Main.Position = goal.Position
	self.Main.Size = goal.Size
	self.Body.Position = bodyPos
	self._logoRest.TextTransparency = 1
	self._collapsed = true
end

function Window:_showBar(visible)
	self._barFade += 1
	local id = self._barFade
	local shown = visible and self.Opener == "Bar"
	if shown then
		self.HomeBar.Visible = true
	end
	tween(self._bar, { BackgroundTransparency = shown and 0.15 or 1 }, 0.25).Completed:Connect(function()
		if not shown and self._barFade == id then
			self.HomeBar.Visible = false
		end
	end)
end

function Window:_finishClose(instant)
	local main = self.Main
	local id = self._anim
	if self.Opener == "Floating" then
		main.Visible = true
		tween(main, { GroupTransparency = 0, BackgroundTransparency = 1 }, instant and 0 or 0.25)
		tween(self._stroke, { Transparency = 1 }, instant and 0 or 0.25)
	else
		tween(self._stroke, { Transparency = 1 }, instant and 0 or 0.35)
		local t = tween(main, { GroupTransparency = 1 }, instant and 0 or 0.35)
		t.Completed:Connect(function()
			if self._anim == id and not self.Visible then
				main.Visible = false
			end
		end)
	end
	self:_showBar(true)
end

function Window:SetOpener(mode)
	if mode ~= "Floating" and mode ~= "Bar" and mode ~= "None" then
		return
	end
	self.Opener = mode
	if self._ready and not self.Visible then
		self._anim += 1
		self:_finishClose(false)
	end
end

function Window:SetVisible(visible)
	if not self._ready or visible == self.Visible then
		return
	end
	if self._settled ~= false then
		self._home = self._collapsed and self:_fullHome() or self.Main.Position
	end
	self._settled = false
	self.Visible = visible
	self._anim += 1
	local id = self._anim
	local main = self.Main
	task.delay(0.36, function()
		if self._anim == id then
			self._settled = true
		end
	end)
	local info = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)

	if visible then
		self:_showBar(false)
		local home = self._home
		main.Visible = true
		tween(main, { GroupTransparency = 0 }, 0.15)
		tween(self._stroke, { Transparency = 0.3 }, 0.15)
		tween(main, { BackgroundTransparency = self.Theme.Transparency }, 0.15)
		TweenService:Create(main, info, {
			Position = home,
			Size = UDim2.fromOffset(self._size.X, self._size.Y),
		}):Play()
		TweenService:Create(self.Body, info, { Position = UDim2.fromOffset(0, 0) }):Play()
		tween(self._logoRest, { TextTransparency = 0 }, 0.25)
		self._collapsed = false
	else
		if not self._collapsed then
			self:_measure()
		end
		local goal, bodyPos = self:_collapsedGoal(self._home)
		TweenService:Create(main, info, goal):Play()
		TweenService:Create(self.Body, info, { Position = bodyPos }):Play()
		tween(self._logoRest, { TextTransparency = 1 }, 0.25)
		self._collapsed = true
		task.delay(0.37, function()
			if self._anim == id then
				self:_finishClose(false)
			end
		end)
	end
end

function Window:Toggle()
	self:SetVisible(not self.Visible)
end

function Window:SetToggleKey(key)
	if type(key) == "string" then
		key = toKeyCode(key)
	end
	self.ToggleKey = key
end

function Window:SetTitle(text)
	self._logoFirst.Text = string.sub(text, 1, 1)
	self._logoRest.Text = string.sub(text, 2)
end

function Window:SetSubtitle(text)
	self._subtitle.Text = text
end

function Window:Destroy()
	for _, connection in ipairs(self.Connections) do
		connection:Disconnect()
	end
	table.clear(self.Connections)
	self.Gui:Destroy()
end

function Library:GetConfig()
	return HttpService:JSONEncode(self.Flags)
end

function Library:LoadConfig(data)
	if type(data) == "string" then
		local ok, decoded = pcall(HttpService.JSONDecode, HttpService, data)
		if not ok then
			return false
		end
		data = decoded
	end
	if type(data) ~= "table" then
		return false
	end
	for flag, value in pairs(data) do
		local element = self.Elements[flag]
		if element and element.Set then
			element:Set(value)
		end
	end
	return true
end

return Library
