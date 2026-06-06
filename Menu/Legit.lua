local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library      = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager  = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local Window = Library:CreateWindow({
    Title            = "BS — Legit",
    Footer           = "BloxStrike",
    ShowCustomCursor = true,
    NotifySide       = "Right",
    Center           = true,
    AutoShow         = true,
})

local Tabs = {
    Visuals  = Window:AddTab("Visuals",     "eye"),
    Exploits = Window:AddTab("Exploits",    "zap"),
    Settings = Window:AddTab("UI Settings", "settings"),
}

-- ── Load UI tab modules ──────────────────────────
loadstring(game:HttpGet(""))() -- placeholder; wire to your raw URLs when hosting

require("Menu/Visuals")(Tabs.Visuals)
require("Menu/Exploits")(Tabs.Exploits, Options)

-- ───────────────────────────────────────────────
--  SETTINGS TAB
-- ───────────────────────────────────────────────

local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu")
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })
MenuGroup:AddButton("Unload", function() Library:Unload() end)
Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("BSLegit")
SaveManager:SetFolder("BSLegit")
ThemeManager:ApplyToTab(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
SaveManager:LoadAutoloadConfig()
