-- Game/Main/Legit/AC/emu.lua
-- BAC emulator. Must run before any other script yields.
-- Uses __namecall hook instead of hookfunction to avoid executor sandboxing.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer       = Players.LocalPlayer

local STATIC_SECRET = "PleaseDontFindThisSenorEhItDoesntReallyMatterTbhItsFineIfYouDo"
local SALT          = "GuelpBAC"
local PARAM         = 256

-- ───────────────────────────────────────────────
--  Packet helpers
-- ───────────────────────────────────────────────

local function buildIdentity(plr, withParam)
    plr = plr or LocalPlayer
    local uid = plr.UserId
    local s = plr.Name .. "|" .. (uid * 2) .. "|" .. (uid * 4) .. "|" .. STATIC_SECRET .. "|" .. SALT
    if withParam then s = s .. "|" .. PARAM end
    return s
end

local function escapeByte(b)
    if b == 0x21 or b == 0x2D or b < 0x20 or b > 0x7E then
        return "!" .. b .. "!"
    end
    return string.char(b)
end

local function packBytes(bytes)
    local out = {}
    for i = 1, #bytes do out[i] = escapeByte(bytes[i]) end
    return table.concat(out)
end

local function unpackEscaped(str)
    local bytes, i = {}, 1
    while i <= #str do
        local n = str:match("^!(%d+)!", i)
        if n then
            bytes[#bytes + 1] = tonumber(n)
            i = i + #n + 2
        else
            bytes[#bytes + 1] = str:byte(i)
            i = i + 1
        end
    end
    return bytes
end

local function toHex(t)
    local out = {}
    if type(t) == "string" then
        for i = 1, #t do out[i] = string.format("%02X", t:byte(i)) end
    else
        for i = 1, #t do out[i] = string.format("%02X", t[i]) end
    end
    return table.concat(out, " ")
end

local function decodePacket(packet)
    local raw = unpackEscaped(packet)
    local marks = {}
    for i = 1, #raw do
        if raw[i] == 0x2D then marks[#marks + 1] = i end
    end
    local function slice(a, b)
        local t = {}
        for i = a, b do t[#t + 1] = raw[i] end
        return t
    end
    local header  = slice(1, (marks[1] or #raw + 1) - 1)
    local digest  = marks[1] and slice(marks[1] + 1, (marks[2] or #raw + 1) - 1) or {}
    local trailer = marks[2] and slice(marks[2] + 1, #raw) or {}
    return {
        raw      = raw,
        nonce    = (header[1] or 0) + (header[2] or 0) * 256,
        seq      = header[3],
        reserved = #header - 3,
        digest   = digest,
        trailer  = trailer,
    }
end

local function buildPacket(nonce, seq, digestBytes, trailerBytes)
    local header = { nonce % 256, math.floor(nonce / 256) % 256, seq % 256, 0, 0, 0, 0, 0 }
    local parts  = { packBytes(header), "-", packBytes(digestBytes) }
    if trailerBytes then
        parts[#parts + 1] = "-"
        parts[#parts + 1] = packBytes(trailerBytes)
    end
    return table.concat(parts)
end

-- ───────────────────────────────────────────────
--  Find BAC remote
-- ───────────────────────────────────────────────

local function findRemote()
    for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
        if d.Name == "BAC" and d:IsA("RemoteEvent") then
            return d
        end
    end
end

local BACRemote = findRemote()
if not BACRemote then
    -- Wait up to 10s for it to appear
    local t0 = os.clock()
    repeat task.wait(0.05) BACRemote = findRemote()
    until BACRemote or (os.clock() - t0) > 10
end

-- ───────────────────────────────────────────────
--  Capture genuine packets via __namecall hook
--  (avoids hookfunction sandboxing issues)
-- ───────────────────────────────────────────────

local captured   = {}
local origIndex  = nil
local hookActive = false

local function captureGenuine(timeout, want)
    if not BACRemote then
        return nil, "no BAC remote found"
    end

    captured   = {}
    hookActive = true

    -- Hook via __namecall on the metatable
    local mt = getrawmetatable(game)
    local old_namecall = mt.__namecall
    setreadonly(mt, false)

    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "FireServer" and self == BACRemote then
            local args = { ... }
            if type(args[1]) == "string" and hookActive then
                captured[#captured + 1] = args[1]
            end
        end
        return old_namecall(self, ...)
    end)

    setreadonly(mt, true)

    -- Wait for packets
    local t0 = os.clock()
    repeat task.wait(0.05)
    until #captured >= (want or 1) or (os.clock() - t0) > (timeout or 8)

    hookActive = false

    -- Restore original namecall
    setreadonly(mt, false)
    mt.__namecall = old_namecall
    setreadonly(mt, true)

    return captured
end

local function sendPacket(packet)
    if BACRemote then
        BACRemote:FireServer(packet)
        return true
    end
    return false
end

-- ───────────────────────────────────────────────
--  Run capture on load
-- ───────────────────────────────────────────────

local identity = buildIdentity(LocalPlayer, true)
print("[BAC] identity:", identity)

local packets = captureGenuine(8, 3)
if packets and #packets > 0 then
    for _, g in ipairs(packets) do
        local p = decodePacket(g)
        print("[BAC] packet:", toHex(p.raw))
        print("[BAC]   nonce=" .. string.format("0x%04X", p.nonce)
            .. " seq=" .. tostring(p.seq)
            .. " digest(" .. #p.digest .. "B)=" .. toHex(p.digest))
        local rebuilt = buildPacket(p.nonce, p.seq or 0, p.digest, (#p.trailer > 0) and p.trailer or nil)
        print("[BAC]   round-trips:", toHex(unpackEscaped(rebuilt)) == toHex(p.raw))
    end
else
    warn("[BAC] no genuine packets captured")
end

-- ───────────────────────────────────────────────
--  Exports
-- ───────────────────────────────────────────────

return {
    buildIdentity  = buildIdentity,
    captureGenuine = captureGenuine,
    decodePacket   = decodePacket,
    buildPacket    = buildPacket,
    sendPacket     = sendPacket,
    packBytes      = packBytes,
    unpackEscaped  = unpackEscaped,
}
