-- Game/Main/Legit/Legit.lua
-- Entry point for game-side logic. Loads all feature modules.

-- Load ESP / Visuals logic
loadfile("Game/Main/Legit/Visuals.lua")()

-- Load Skin Changer
loadfile("Exploits/SkinChanger.lua")()
