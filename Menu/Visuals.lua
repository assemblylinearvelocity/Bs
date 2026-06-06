-- Menu/Visuals.lua
-- Builds the Visuals tab UI. Called from Legit.lua with the tab object.

return function(tab)
    local ESPGroup   = tab:AddLeftGroupbox("ESP")
    local WorldGroup = tab:AddRightGroupbox("World")

    -- ── ESP ──────────────────────────────────────

    ESPGroup:AddToggle("ESPEnabled", {
        Text    = "Enable ESP",
        Default = false,
    })

    ESPGroup:AddToggle("ESPBoxes", {
        Text    = "Boxes",
        Default = false,
    })

    ESPGroup:AddToggle("ESPSkeleton", {
        Text    = "Skeleton",
        Default = false,
    })

    ESPGroup:AddToggle("ESPNames", {
        Text    = "Names",
        Default = false,
    })

    ESPGroup:AddToggle("ESPHealth", {
        Text    = "Health Bar",
        Default = false,
    })

    ESPGroup:AddToggle("ESPDistance", {
        Text    = "Distance",
        Default = false,
    })

    ESPGroup:AddDivider()

    ESPGroup:AddLabel("ESP Color"):AddColorPicker("ESPColor", {
        Default = Color3.fromRGB(255, 50, 50),
    })

    ESPGroup:AddLabel("Team Check"):AddToggle("ESPTeamCheck", {
        Text    = "Team Check",
        Default = true,
    })

    ESPGroup:AddSlider("ESPMaxDistance", {
        Text     = "Max Distance",
        Default  = 500,
        Min      = 50,
        Max      = 2000,
        Rounding = 0,
        Suffix   = " st",
    })

    -- ── World ─────────────────────────────────────

    WorldGroup:AddToggle("Chams", {
        Text    = "Chams",
        Default = false,
    })

    WorldGroup:AddLabel("Chams Color"):AddColorPicker("ChamsColor", {
        Default = Color3.fromRGB(255, 50, 50),
    })

    WorldGroup:AddDivider()

    WorldGroup:AddToggle("BulletTracers", {
        Text    = "Bullet Tracers",
        Default = false,
    })

    WorldGroup:AddToggle("HitmarkerESP", {
        Text    = "Hitmarker ESP",
        Default = false,
    })

    WorldGroup:AddToggle("DropItemESP", {
        Text    = "Dropped Items ESP",
        Default = false,
    })
end
