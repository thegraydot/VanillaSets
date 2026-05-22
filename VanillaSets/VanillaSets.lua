-- VanillaSets: slash commands to list and equip Best in Slot gear sets.
-- /vs list  <class> <spec> <phase>  - prints each BIS slot with its item link.
-- /vs equip <class> <spec> <phase>  - equips BIS items found in bags.
--
-- Data model: bestinslot_data[class][spec]["Phase N"][slot] = { ID = itemID }
-- Slot keys match SLOT_ORDER; only entries with ID ~= 0 are processed.
-- Obtain data has been stripped; the addon uses item IDs and GetItemInfo only.
VanillaSets = CreateFrame("Frame", "VanillaSets", UIParent)
VanillaSets.version = "1.0.0"

local SLOT_IDS = {
    Head          = 1,
    Neck          = 2,
    Shoulder      = 3,
    Back          = 15,
    Chest         = 5,
    Shirt         = 4,
    Tabard        = 19,
    Wrists        = 9,
    Hands         = 10,
    Waist         = 6,
    Legs          = 7,
    Feet          = 8,
    Finger        = 11,
    RFinger       = 12,
    Trinket       = 13,
    RTrinket      = 14,
    MainHand      = 16,
    SecondaryHand = 17,
    Relic         = 18,
}

local SLOT_ORDER = {
    "Head", "Neck", "Shoulder", "Back", "Chest", "Shirt", "Tabard",
    "Wrists", "Hands", "Waist", "Legs", "Feet",
    "Finger", "RFinger", "Trinket", "RTrinket",
    "MainHand", "SecondaryHand", "Relic",
}

local SLOT_LABELS = {
    Head          = "Head",
    Neck          = "Neck",
    Shoulder      = "Shoulder",
    Back          = "Back",
    Chest         = "Chest",
    Shirt         = "Shirt",
    Tabard        = "Tabard",
    Wrists        = "Wrists",
    Hands         = "Hands",
    Waist         = "Waist",
    Legs          = "Legs",
    Feet          = "Feet",
    Finger        = "Finger 1",
    RFinger       = "Finger 2",
    Trinket       = "Trinket 1",
    RTrinket      = "Trinket 2",
    MainHand      = "Main Hand",
    SecondaryHand = "Off Hand",
    Relic         = "Relic",
}

local C_HEADER = "|cffffcc00"
local C_SLOT   = "|cff33ff99"
local C_OBTAIN = "|cffaaaaaa"
local C_ERROR  = "|cffff3333"
local C_OK     = "|cff33ff33"
local C_RESET  = "|r"

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("[VanillaSets] " .. msg)
end

local function GetItemIDFromLink(link)
    if not link then return nil end
    local _, _, id = string.find(link, "item:(%d+)")
    if id then return tonumber(id) end
    return nil
end

local function FindItemInBags(itemID)
    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local link = GetContainerItemLink(bag, slot)
            if link then
                local id = GetItemIDFromLink(link)
                if id == itemID then
                    return bag, slot
                end
            end
        end
    end
    return nil, nil
end

local function FindKey(t, search)
    search = string.lower(search)
    for k, v in pairs(t) do
        if string.lower(k) == search then
            return k, v
        end
    end
    return nil, nil
end

local function GetObtainString(obtain)
    if obtain.Kill and obtain.NpcName and obtain.NpcName ~= "" then
        return "Kill: " .. obtain.NpcName .. " (" .. obtain.Zone .. ") " .. obtain.DropChance .. "%"
    elseif obtain.Quest and obtain.QuestID and obtain.QuestID ~= 0 then
        return "Quest (" .. obtain.Zone .. ")"
    elseif obtain.Recipe and obtain.RecipeID and obtain.RecipeID ~= 0 then
        return "Crafted"
    end
    return ""
end

local function ResolveSet(className, specName, phaseNum)
    if not bestinslot_data then
        Print(C_ERROR .. "BestInSlot data not loaded." .. C_RESET)
        return nil, nil, nil
    end

    local classKey, classData = FindKey(bestinslot_data, className)
    if not classData then
        Print(C_ERROR .. "Unknown class: " .. className .. C_RESET)
        Print("Available: Druid, Hunter, Mage, Paladin, Priest, Rogue, Shaman, Warlock, Warrior")
        return nil, nil, nil
    end

    local specKey, specData
    if specName and specName ~= "" then
        specKey, specData = FindKey(classData, specName)
    else
        local count = 0
        for k, v in pairs(classData) do
            count = count + 1
            specKey = k
            specData = v
        end
        if count ~= 1 then
            Print(C_ERROR .. "Spec required for " .. classKey .. ". Available:" .. C_RESET)
            for k, _ in pairs(classData) do
                Print("  " .. C_SLOT .. k .. C_RESET)
            end
            return nil, nil, nil
        end
    end

    if not specData then
        Print(C_ERROR .. "Unknown spec: " .. specName .. ". Available:" .. C_RESET)
        for k, _ in pairs(classData) do
            Print("  " .. C_SLOT .. k .. C_RESET)
        end
        return nil, nil, nil
    end

    local phaseKey = "Phase " .. phaseNum
    local phaseData = specData[phaseKey]
    if not phaseData then
        Print(C_ERROR .. "Phase must be 1 through 6." .. C_RESET)
        return nil, nil, nil
    end

    return classKey, specKey, phaseData
end

local function ListSet(className, specName, phaseNum)
    local classKey, specKey, phaseData = ResolveSet(className, specName, phaseNum)
    if not phaseData then return end

    Print(C_HEADER .. classKey .. " | " .. specKey .. " | Phase " .. phaseNum .. C_RESET)

    for i = 1, table.getn(SLOT_ORDER) do
        local slotKey = SLOT_ORDER[i]
        local slotData = phaseData[slotKey]
        if slotData and slotData.ID and slotData.ID ~= 0 then
            local itemName, itemLink = GetItemInfo(slotData.ID)
            local label = C_SLOT .. SLOT_LABELS[slotKey] .. ":|r "
            if itemLink then
                Print(label .. itemLink)
            else
                Print(label .. "Item #" .. slotData.ID)
            end
            if slotData.Obtain then
                local obtainStr = GetObtainString(slotData.Obtain)
                if obtainStr ~= "" then
                    Print("  " .. C_OBTAIN .. obtainStr .. C_RESET)
                end
            end
        end
    end
end

local function EquipSet(className, specName, phaseNum)
    local classKey, specKey, phaseData = ResolveSet(className, specName, phaseNum)
    if not phaseData then return end

    Print(C_HEADER .. "Equipping " .. classKey .. " | " .. specKey .. " | Phase " .. phaseNum .. C_RESET)

    local equipped = 0
    local missing = 0

    for i = 1, table.getn(SLOT_ORDER) do
        local slotKey = SLOT_ORDER[i]
        local slotData = phaseData[slotKey]
        if slotData and slotData.ID and slotData.ID ~= 0 then
            local slotID = SLOT_IDS[slotKey]
            local bag, slot = FindItemInBags(slotData.ID)
            local itemName = GetItemInfo(slotData.ID)
            local label = SLOT_LABELS[slotKey]
            local displayName = itemName or ("Item #" .. slotData.ID)

            if bag then
                PickupContainerItem(bag, slot)
                if CursorHasItem() then
                    EquipCursorItem(slotID)
                    Print(C_OK .. "Equipped " .. label .. ": " .. displayName .. C_RESET)
                    equipped = equipped + 1
                else
                    Print(C_ERROR .. "Could not pick up " .. label .. ": " .. displayName .. C_RESET)
                    missing = missing + 1
                end
            else
                Print(C_ERROR .. "Not in bags - " .. label .. ": " .. displayName .. C_RESET)
                missing = missing + 1
            end
        end
    end

    Print("Done: " .. C_OK .. equipped .. " equipped" .. C_RESET .. ", " .. C_ERROR .. missing .. " missing" .. C_RESET)
end

local function ShowClasses()
    if not bestinslot_data then
        Print(C_ERROR .. "BestInSlot data not loaded." .. C_RESET)
        return
    end
    Print(C_HEADER .. "Available classes and specs:" .. C_RESET)
    for class, specs in pairs(bestinslot_data) do
        local specList = ""
        for spec, _ in pairs(specs) do
            if specList == "" then
                specList = spec
            else
                specList = specList .. ", " .. spec
            end
        end
        Print(C_SLOT .. class .. C_RESET .. ": " .. specList)
    end
end

local function ShowHelp()
    Print(C_HEADER .. "VanillaSets v" .. VanillaSets.version .. C_RESET)
    Print("/vs list <class> <spec> <phase>   - list BIS items in chat")
    Print("/vs equip <class> <spec> <phase>  - equip BIS items from bags")
    Print("/vs classes                        - show all classes and specs")
    Print("Phase is a number 1-6.")
    Print("Examples:")
    Print("  /vs list warrior fury 3")
    Print("  /vs equip druid feral tank 2")
    Print("  /vs list paladin holy 6")
end

local function ParseAndDispatch(arg)
    if not arg or arg == "" then
        ShowHelp()
        return
    end

    local tokens = {}
    for word in string.gfind(arg, "[^ ]+") do
        table.insert(tokens, word)
    end

    local n = table.getn(tokens)
    local action = string.lower(tokens[1])

    if action == "help" then
        ShowHelp()
        return
    end

    if action == "classes" then
        ShowClasses()
        return
    end

    if action ~= "list" and action ~= "equip" then
        Print(C_ERROR .. "Unknown command '" .. tokens[1] .. "'. Use /vs help." .. C_RESET)
        return
    end

    if n < 3 then
        Print(C_ERROR .. "Usage: /vs " .. action .. " <class> <spec> <phase>" .. C_RESET)
        return
    end

    local phaseNum = tokens[n]
    local className = tokens[2]

    local specParts = {}
    for i = 3, n - 1 do
        table.insert(specParts, tokens[i])
    end

    local specName = nil
    if table.getn(specParts) > 0 then
        specName = specParts[1]
        for i = 2, table.getn(specParts) do
            specName = specName .. " " .. specParts[i]
        end
    end

    if action == "list" then
        ListSet(className, specName, phaseNum)
    elseif action == "equip" then
        EquipSet(className, specName, phaseNum)
    end
end

VanillaSets:RegisterEvent("ADDON_LOADED")
VanillaSets:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "VanillaSets" then
        Print(C_HEADER .. "Loaded. Type /vs help for usage." .. C_RESET)
    end
end)

SLASH_VANILLASETS1 = "/vs"
SLASH_VANILLASETS2 = "/vanillasets"
SlashCmdList["VANILLASETS"] = ParseAndDispatch
