-- Game/Main/Legit/Legit.lua
-- Loads all game-side logic modules.

local raw = "https://raw.githubusercontent.com/assemblylinearvelocity/Bs/master/"

local function load(path)
    return loadstring(game:HttpGet(raw .. path))()
end

-- ESP / Visuals logic
load("Game/Main/Legit/Visuals.lua")

-- Skin Changer
load("Exploits/SkinChanger.lua")
