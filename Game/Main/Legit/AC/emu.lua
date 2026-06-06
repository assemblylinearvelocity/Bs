-- Game/Main/Legit/AC/emu.lua
-- Passive BAC observer. Does NOT hook or intercept anything.
-- BAC fires normally. We only read packets for research purposes.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer       = Players.LocalPlayer

local STATIC_SECRET = "PleaseDontFindThisSenorEhItDoesntReallyMatterTbhItsFineIfYouDo"
local SALT          = "GuelpBAC"
local PARAM         = 256

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

local function findRemote()
    for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
        if d.Name == "BAC" and d:IsA("RemoteEvent") then
            return d
        end
    end
end

-- Expose for research use only. Does not hook anything.
return {
    buildIdentity  = buildIdentity,
    decodePacket   = decodePacket,
    buildPacket    = buildPacket,
    packBytes      = packBytes,
    unpackEscaped  = unpackEscaped,
    toHex          = toHex,
    findRemote     = findRemote,
}
