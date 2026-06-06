-- Loader.lua
-- Installs __namecall hook on BAC immediately (no yields),
-- then fetches all scripts in parallel and executes in order.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local raw = "https://raw.githubusercontent.com/assemblylinearvelocity/Bs/master/"

-- ── Step 1: Install BAC __namecall intercept BEFORE any yield ────────────────
-- This runs synchronously so we never miss packet #1.
-- It's a pure pass-through — the emu will take over once loaded.

local function installEarlyHook()
    local ok, mt = pcall(getrawmetatable, game)
    if not ok or not mt then return end

    local old_namecall = rawget(mt, "__namecall")
    if not old_namecall then return end

    pcall(setreadonly, mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        -- pure pass-through, touches nothing
        return old_namecall(self, ...)
    end)
    pcall(setreadonly, mt, true)

    -- stash so emu.lua can reference it
    getgenv().__BAC_loader_namecall = old_namecall
end

installEarlyHook()

-- ── Step 2: Fetch all scripts in parallel ────────────────────────────────────

local scripts = {}

task.spawn(function() scripts.emu  = game:HttpGet(raw .. "Game/Main/Legit/AC/emu.lua")  end)
task.spawn(function() scripts.menu = game:HttpGet(raw .. "Menu/Legit.lua")               end)
task.spawn(function() scripts.game = game:HttpGet(raw .. "Game/Main/Legit/Legit.lua")    end)

repeat task.wait() until scripts.emu and scripts.menu and scripts.game

-- ── Step 3: Execute in order ─────────────────────────────────────────────────

-- 1. Emulator — sets up proper __namecall capture, reads packets
loadstring(scripts.emu)()

-- 2. Menu — UI (needs Library)
loadstring(scripts.menu)()

-- 3. Game logic — ESP + SkinChanger (needs Library + emu)
loadstring(scripts.game)()
