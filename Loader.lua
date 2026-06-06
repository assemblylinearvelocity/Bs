-- Loader.lua
-- Execute this in your exploit. Loads in the correct order.

local raw = "https://raw.githubusercontent.com/assemblylinearvelocity/Bs/master/"

local function load(path)
    return loadstring(game:HttpGet(raw .. path))()
end

-- ── Step 1: AC Emulator (must run first, before anything fires) ──
load("Game/Main/Legit/AC/emu.lua")

-- ── Step 2: UI Library + Menu ────────────────────────────────────
load("Menu/Legit.lua")

-- ── Step 3: Game logic (ESP, Skin Changer) ───────────────────────
load("Game/Main/Legit/Legit.lua")
