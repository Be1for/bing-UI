BingUI
Roblox UI library (Luau), styled after the "Bing" menu: logo and tab buttons on the left, content on the right, translucent dark theme with an indigo accent, Montserrat font, Lucide icons, fade and slide animations.
test.luau is a single LocalScript with the library and the demo menu inside, just paste it into a LocalScript in StarterPlayerScripts.
API
local BingUI = require(game.ReplicatedStorage.BingUI)

local Window = BingUI:CreateWindow({
 Title = "Bing",                       -- big logo text
 Subtitle = "Official TG @channel",    -- text above the content
 Size = UDim2.fromOffset(780, 500),    -- optional
 Scale = 1,                            -- optional, fits the screen automatically if omitted
 ToggleKey = Enum.KeyCode.RightShift,  -- show / hide the menu
 Opener = "Floating",                  -- "Floating" (menu folds into a draggable "B" button), "Bar" (iOS style bar at the bottom) or "None"
 Visible = true,                       -- false = start closed
 Theme = { Accent = Color3.fromRGB(100, 116, 255), Transparency = 0.12 }, -- optional theme overrides
})

local Tab = Window:AddTab("Visuals")
Elements
Every element can live in a tab or in a section.
-- checkbox
local t = Tab:AddToggle({ Name = "Box", Default = true, Flag = "Box", Callback = function(v) end })

-- checkboxes in a grid (4 per row like in the picture)
local grid = Tab:AddToggleGrid({ Columns = 4 })
grid:AddToggle({ Name = "Name", Default = true })

-- slider with the value in the middle and the name on the right
local s = Tab:AddSlider({ Name = "Radar size", Min = 0, Max = 5, Decimals = 1, Default = 0, Suffix = "", Callback = function(v) end })

-- keybind: click the box, press a key (Esc / Backspace = None)
local k = Tab:AddKeybind({
 Name = "Menu key",
 Default = Enum.KeyCode.RightShift,  -- or "RightShift"
 Mode = "Toggle",                    -- "Hold" calls Callback(true) on press and Callback(false) on release
 Callback = function() end,          -- the key was pressed
 ChangedCallback = function(keyCode) Window:SetToggleKey(keyCode) end, -- the key was rebound
})

-- button / several buttons in one row
Tab:AddButton({ Name = "Save settings", Callback = function() end })
Tab:AddButtons({
 { Name = "Load", Callback = function() end },
 { Name = "Exit", Callback = function() end },
})

-- text (RichText works, \n for new lines)
local l = Tab:AddLabel('FPS <font color="#8CAFEB">120</font>')
l:Set("new text")

-- radio buttons (circles)
local r = Tab:AddRadio({ Name = "Part:", Options = { "Head", "Neck", "Chest", "Belly" }, Default = "Head", Callback = function(v) end })

-- dropdown (single or Multi = true, then the value is a table)
local d = Tab:AddDropdown({ Name = "Target", Values = { "Closest", "Lowest HP" }, Default = "Closest", Callback = function(v) end })
d:SetValues({ "A", "B" })

-- image
Tab:AddImage({ Image = "rbxassetid://214399894", Height = 140 })

-- images can be rbxassetid://..., a number, or an http(s) link.
-- links are downloaded with game:HttpGet, saved with writefile into BingUI.AssetFolder ("BingUI")
-- and shown with getcustomasset, so they only work where those functions exist

-- image picker (grid of cards with pictures)
local p = Tab:AddImagePicker({
 Columns = 3, Height = 260, Default = "one",
 Values = { { name = "one", image = "rbxassetid://123", callback = function() end } },
 Callback = function(name) end,
})
p:Add({ name = "two", image = 456 })

-- collapsible section
local sec = Tab:AddSection({ Name = "Basic settings", Collapsed = true })
sec:AddToggle({ Name = "Something" })
sec:SetOpen(true)
Toggles, sliders, radios, keybinds, dropdowns and image pickers have :Set(value, silent) and :Get(). The callback fires only when the value actually changes; with silent = true it does not fire at all. The Default value does not fire the callback.
Window
Window:SelectTab("Visuals")   -- or a number, or the tab object
Window:Toggle()               -- clicking the logo also closes / opens the menu
Window:SetVisible(false)     -- fades out
Window:SetToggleKey(Enum.KeyCode.Insert)
Window:SetOpener("Bar")       -- "Floating" / "Bar" / "None"
Window:SetTitle("Bing")
Window:SetSubtitle("text")
Window:Destroy()
Config
Everything with a Flag goes into BingUI.Flags.
local json = BingUI:GetConfig()   -- JSON string
BingUI:LoadConfig(json)           -- string or table
