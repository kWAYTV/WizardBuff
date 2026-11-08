local _, ns = ...

-- Multi-mage coordination. Every mage running the addon announces itself.
-- Raid groups are split between them automatically (the same split on
-- every client, so nothing has to be negotiated), and anyone can override
-- the split from the assignment window. Overrides are shared with a
-- revision stamp; the newest wins.

local PREFIX = "WizBuff"
local PROTO = "1"

ns.peers = {}                                   -- guid -> { version, seen }
ns.manual = { rev = 0, by = "", groups = {} }   -- groups[g] = guid
ns.owners = nil                                 -- group -> guid, or nil when everything is ours

local myGuid
local queue = {}
local flushTimer

local function channel()
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then return "INSTANCE_CHAT" end
    if IsInRaid() then return "RAID" end
    if IsInGroup() then return "PARTY" end
end

local function lockedDown()
    local fn = C_ChatInfo.InChatMessagingLockdown
    return fn and ns.SafeCall(fn) and true or false
end

local flush

local function schedule(delay)
    if flushTimer then return end
    flushTimer = C_Timer.NewTimer(delay, flush)
end

-- Result codes from Enum.SendAddonMessageResult that mean "try later".
local RETRY = { [3] = true, [8] = true, [9] = true, [11] = true }

flush = function()
    flushTimer = nil
    local ch = channel()
    if not ch then wipe(queue); return end
    if lockedDown() then schedule(5); return end
    for kind, msg in pairs(queue) do
        local ok, result = pcall(C_ChatInfo.SendAddonMessage, PREFIX, msg, ch)
        if not ok or (type(result) == "number" and RETRY[result]) then
            break
        end
        queue[kind] = nil
    end
    if next(queue) then schedule(3) end
end

-- Messages of the same kind replace each other, so bursts collapse.
local function send(kind, msg)
    if not ns.db.coordinate or not channel() then return end
    queue[kind] = msg
    schedule(1)
end

local function encodeAssign()
    local parts = {}
    for g, guid in pairs(ns.manual.groups) do parts[#parts + 1] = g .. "=" .. guid end
    return "A:" .. ns.manual.rev .. ":" .. ns.manual.by .. ":" .. table.concat(parts, ",")
end

function ns.SendHello()
    if not myGuid then return end
    send("H", "H:" .. PROTO .. ":" .. myGuid .. ":" .. ns.version)
end

local function sendAssign()
    if ns.manual.rev > 0 then send("A", encodeAssign()) end
end

local function applyAssign(rev, by, body)
    rev = tonumber(rev)
    if not rev then return end
    local cur = ns.manual
    if rev < cur.rev or (rev == cur.rev and by <= cur.by) then return end
    local groups = {}
    for g, guid in body:gmatch("(%d)=([^,]+)") do groups[tonumber(g)] = guid end
    ns.manual = { rev = rev, by = by, groups = groups }
    ns.Fire("ASSIGN_CHANGED")
end

local function onMessage(prefix, text, _, sender)
    if prefix ~= PREFIX or ns.IsSecret(text) or ns.IsSecret(sender) then return end
    if not ns.db.coordinate then return end
    local kind, a, b, c = strsplit(":", text, 4)
    if kind == "H" then
        local guid, version = b, c
        if a ~= PROTO or not guid or guid == myGuid then return end
        local isNew = ns.peers[guid] == nil
        ns.peers[guid] = { version = version, seen = GetTime() }
        if isNew then
            ns.SendHello()
            sendAssign()
            ns.Fire("ASSIGN_CHANGED")
        end
    elseif kind == "A" then
        if b == myGuid then return end
        applyAssign(a, b or "", c or "")
    end
end

-- Addon mages currently in the group, sorted so every client agrees.
function ns.ActivePeers()
    local list = {}
    for guid in pairs(ns.peers) do
        local rec = ns.byGuid[guid]
        if rec and not rec.offline then list[#list + 1] = guid end
    end
    table.sort(list)
    return list
end

-- Every mage in the group, with or without the addon.
function ns.GroupMages()
    local list = {}
    for _, rec in ipairs(ns.members) do
        if rec.class == "MAGE" and not rec.isPet then
            list[#list + 1] = { guid = rec.guid, name = rec.name, hasAddon = ns.peers[rec.guid] ~= nil }
        end
    end
    table.sort(list, function(x, y) return x.guid < y.guid end)
    return list
end

function ns.RecomputeOwners()
    ns.owners = nil
    if not ns.db.coordinate or not IsInRaid() then return end
    local peers = ns.ActivePeers()

    local groups, present = {}, {}
    for _, rec in ipairs(ns.members) do
        if not present[rec.group] then present[rec.group] = true; groups[#groups + 1] = rec.group end
    end
    table.sort(groups)

    local owners, hasManual = {}, false
    for g, guid in pairs(ns.manual.groups) do
        if present[g] and ns.byGuid[guid] then owners[g] = guid; hasManual = true end
    end
    if #peers <= 1 and not hasManual then return end

    local i = 0
    for _, g in ipairs(groups) do
        if not owners[g] and #peers > 0 then
            i = i + 1
            owners[g] = peers[(i - 1) % #peers + 1]
        end
    end
    ns.owners = owners
end

function ns.IsMine(rec)
    local owners = ns.owners
    if not owners then return true end
    local owner = owners[rec.group]
    return owner == nil or owner == myGuid
end

function ns.OwnerOf(group)
    return ns.owners and ns.owners[group]
end

function ns.SetGroupOwner(group, guid)
    ns.manual.groups[group] = guid
    ns.manual.rev = GetServerTime()
    ns.manual.by = myGuid or ""
    sendAssign()
    ns.Fire("ASSIGN_CHANGED")
end

function ns.AutoAssign()
    ns.manual = { rev = GetServerTime(), by = myGuid or "", groups = {} }
    send("A", encodeAssign())
    ns.Fire("ASSIGN_CHANGED")
end

function ns.IsManualAssign()
    return next(ns.manual.groups) ~= nil
end

local lastRosterKey

function ns.InitSync()
    myGuid = UnitGUID("player")
    C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
    ns.peers[myGuid] = { version = ns.version, seen = GetTime() }
    ns.On("CHAT_MSG_ADDON", onMessage)
    ns.On("ENCOUNTER_END", function() if next(queue) then schedule(1) end end)
    ns.On("GROUP_LEFT", function()
        wipe(ns.peers)
        ns.peers[myGuid] = { version = ns.version, seen = GetTime() }
        ns.manual = { rev = 0, by = "", groups = {} }
        wipe(queue)
        lastRosterKey = nil
    end)

    -- Say hello whenever the group's membership changes.
    ns.Listen("ROSTER_SCANNED", function()
        if not IsInGroup() then return end
        local guids = {}
        for _, rec in ipairs(ns.members) do
            if not rec.isPet then guids[#guids + 1] = rec.guid end
        end
        table.sort(guids)
        local key = table.concat(guids, ",")
        if key ~= lastRosterKey then
            lastRosterKey = key
            ns.SendHello()
        end
    end)
end
