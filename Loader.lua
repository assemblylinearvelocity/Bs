-- Loader.lua
-- IMPORTANT: Hook BAC FireServer BEFORE any yields so we never miss packet 1.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local raw = "https://raw.githubusercontent.com/assemblylinearvelocity/Bs/master/"

-- ── Step 1: Grab BAC remote instantly and install a passthrough hook ──────────
-- This runs synchronously before any HttpGet yields.
-- The hook is a no-op passthrough; emu.lua will upgrade it once loaded.

local BACRemote = nil
local EarlyQueue = {} -- packets captured before emu is ready

local function findBAC()
    for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
        if d.Name == "BAC" and d:IsA("RemoteEvent") then
            return d
        end
    end
end

-- Try to find it immediately (it may already exist on join)
BACRemote = findBAC()

local function installEarlyHook(remote)
    local fs = remote.FireServer
    local original
    original = hookfunction(fs, function(self, ...)
        -- pass-through: do not interfere, just let it fire normally
        return original(self, ...)
    end)
    -- Store original so emu can use it
    getgenv().__BAC_original_FireServer = original
    getgenv().__BAC_remote = remote
end

if BACRemote then
    installEarlyHook(BACRemote)
else
    -- Not ready yet — watch for it in background while we download
    task.spawn(function()
        local remote = ReplicatedStorage:WaitForChild("Remotes", 10)
        if not remote then
            -- try descendants
            local t0 = os.clock()
            repeat
                task.wait()
                BACRemote = findBAC()
            until BACRemote or (os.clock() - t0) > 10
        else
            BACRemote = remote:WaitForChild("BAC", 10)
        end
        if BACRemote then
            installEarlyHook(BACRemote)
        end
    end)
end

-- ── Step 2: Download all scripts in parallel ──────────────────────────────────

local scripts = {
    emu      = nil,
    menu     = nil,
    game     = nil,
}

-- Fetch all three simultaneously
local threads = {
    task.spawn(function() scripts.emu  = game:HttpGet(raw .. "Game/Main/Legit/AC/emu.lua") end),
    task.spawn(function() scripts.menu = game:HttpGet(raw .. "Menu/Legit.lua") end),
    task.spawn(function() scripts.game = game:HttpGet(raw .. "Game/Main/Legit/Legit.lua") end),
}

-- Wait for all fetches to complete
repeat task.wait() until scripts.emu and scripts.menu and scripts.game

-- ── Step 3: Execute in correct order ─────────────────────────────────────────

-- 1. Emulator — upgrades the early hook and starts monitoring
loadstring(scripts.emu)()

-- 2. Menu — UI (depends on Library)
loadstring(scripts.menu)()

-- 3. Game logic — ESP, SkinChanger (depends on Library + emu)
loadstring(scripts.game)()
