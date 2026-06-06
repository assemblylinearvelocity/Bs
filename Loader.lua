-- Loader.lua
-- Simple parallel loader. No hooks. BAC fires untouched.

local raw = "https://raw.githubusercontent.com/assemblylinearvelocity/Bs/master/"

local scripts = {}
task.spawn(function() scripts.menu = game:HttpGet(raw .. "Menu/Legit.lua")  end)
task.spawn(function() scripts.game = game:HttpGet(raw .. "Game/Main/Legit/Legit.lua") end)

repeat task.wait() until scripts.menu and scripts.game

loadstring(scripts.menu)()
loadstring(scripts.game)()
