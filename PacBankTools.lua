
-- Load Required Libraries
local LAM2 = LibStub:GetLibrary("LibAddonMenu-2.0")
--local LIBMW = LibStub:GetLibrary("LibMsgWin-1.0")

-- Initialize our Namespace Table
PacsBankAddon = {}

PacsBankAddon.name = "PacBankTools"
PacsBankAddon.version = "1.3.0"


-- Initialize our Variables
function PacsBankAddon:Initialize()
    PacsBankAddon.CreateSettingsWindow()

    time = os.date("%m/%d/%Y %H:%M:%S")

    PacsBankAddon.savedVariables = ZO_SavedVars:NewAccountWide("PacBankToolsSavedVariables", 1, nil, {})

    enableDebug = PacsBankAddon.savedVariables.enableDebug
    activeGuild = PacsBankAddon.savedVariables.activeGuild
    activeGuildID = PacsBankAddon.savedVariables.activeGuildID


    -- If this is the first run, or the saved settings file is missing lets set the first guild as the default
    if isempty(activeGuildID) then
        activeGuildID = GetGuildId(1)
        activeGuild = GetGuildName(activeGuildID)
        PacsBankAddon.savedVariables.activeGuild = activeGuild
        PacsBankAddon.savedVariables.activeGuildID = activeGuildID
    end

    -- -- Currently the Saved Settings saves the Guilds Name.  Lets grab the active guilds index ID.  
    -- for guildIndex = 1, 5 do
    --     if activeGuild == GetGuildName(guildIndex) then
    --         PacsBankAddon.savedVariables.activeGuildID = guildIndex
    --     end
    -- end

    -- Grab the active guilds name and number of members from the ESO API
    guildName = GetGuildName(activeGuildID)
    guildMemberNum = GetNumGuildMembers(activeGuildID)

    PacsBankAddon.UpdateGuildRoster()

    if PacsBankAddon.savedVariables.enableBankExport == true then
        PacsBankAddon.UpdateGuildHistory()
        PacsBankAddon.UpdateGuildStoreHistory()

        -- Poll the Server every 2.5 seconds to get Guild Bank History filled. 
        EVENT_MANAGER:RegisterForUpdate("PacsUpdateGuildHistory", 2500, PacsBankAddon.LoadGuildHistoryBackfill)

        -- Poll the Server every 2.5 seconds to get Guild Store History filled. 
        EVENT_MANAGER:RegisterForUpdate("PacsUpdateGuildStore", 2500, PacsBankAddon.LoadGuildStoreBackfill)
    end


    PacsBankAddon.savedVariables.lastUpdate = time


    -- Debug output if we have that enabled. 
    if enableDebug == true then
        d("Active Guild " .. activeGuild)
        d("Active Guild ID " .. activeGuildID)
        d("PacBankTools Init Finished")
        d(time)
    end
end


-- Run when Addon Loads
function PacsBankAddon.OnAddOnLoaded(event, addonName)
    -- The event fires each time *any* addon loads - but we only care about when our own addon loads.
    if addonName == PacsBankAddon.name then
        PacsBankAddon:Initialize()
    end
end



-- Convert Seconds to Hours, Min, Seconds
function PacsBankAddon.SecondsToClock(seconds)
    local seconds = tonumber(seconds)
  
    if seconds <= 0 then
      return "00:00:00";
    else
      hours = string.format("%02.f", math.floor(seconds/3600));
      mins = string.format("%02.f", math.floor(seconds/60 - (hours*60)));
      secs = string.format("%02.f", math.floor(seconds - hours*3600 - mins *60));
      return hours..":"..mins..":"..secs
    end
end


-- Function to Check if a Variable is empty
function isempty(s)
    return s == nil or s == ''
end


-- Update Guild Roster in Saved Variables
function PacsBankAddon.UpdateGuildRoster(extra)
    local activeGUildID = PacsBankAddon.savedVariables.activeGuildID
    local enableDebug = PacsBankAddon.savedVariables.enableDebug
    -- local guildName = GetGuildName(activeGuildID)
    local guildMemberNum = GetNumGuildMembers(activeGuildID)

    -- Grab the guild roster from the ESO API
    local masterList = {}
    for guildMemberIndex = 1, guildMemberNum do
        local displayName, note, rankIndex, status, secsSinceLogoff = GetGuildMemberInfo(activeGuildID, guildMemberIndex)

        if status == 1 then
            statusString = "Online"
        elseif status == 2 then
            statusString = "Away"
        elseif status == 3 then
            statusString = "Do Not Distrub"
        elseif status == 4 then
            statusString = "Offline"
        end

        local data = {
                        index = guildMemberIndex,
                        displayName = displayName,
                        note = note,
                        rankIndex = rankIndex,
                        rankName = GetGuildRankCustomName(activeGuildID, rankIndex),
                        status = status,
                        statusString = statusString,
                        secsSinceLogoff = secsSinceLogoff,
                        logoffString = PacsBankAddon.SecondsToClock(secsSinceLogoff),
                    }
        masterList[guildMemberIndex] = data
    end

    PacsBankAddon.savedVariables.guildRoster = masterList

    if enableDebug == true then
        d("Updated Saved Var Guild roster with " .. guildMemberNum .. " members.")
    end
end


-- Update Guild Bank History in Saved Variables
function PacsBankAddon.UpdateGuildHistory()
    local activeGuildID = PacsBankAddon.savedVariables.activeGuildID
    local enableDebug = PacsBankAddon.savedVariables.enableDebug

    RequestGuildHistoryCategoryOlder(activeGuildID, GUILD_HISTORY_BANK)
    local numGuildBankEvents = GetNumGuildEvents(activeGuildID, GUILD_HISTORY_BANK)
    local guildBankHistory = {}
    for GuildBankEventsIndex = 1, numGuildBankEvents do
        local eventType, secsSinceEvent, displayName, count, itemLink = GetGuildEventInfo(activeGuildID, GUILD_HISTORY_BANK, GuildBankEventsIndex)
        local timestamp = os.date("%m/%d/%Y %H:%M:%S %z", (os.time() - secsSinceEvent))

        if eventType == 21 then
            eventName = "Bankgold Added"
        elseif eventType == 22 then
            eventName = "Bankgold Removed"
        elseif eventType == 14 then
            eventName = "Bankitem Removed"
        elseif eventType == 13 then
            eventName = "Bankitem Added"
        else
            eventName = "Unknown"
        end

        avgPrice = {}
        avgPrice = TamrielTradeCentrePrice:GetPriceInfo(itemLink)
        if isempty(avgPrice) == false then
            avgPrice = avgPrice['Avg']
        end 

        local data = {
                    eventName = eventName,
                    eventType = eventType,
                    secsSinceEvent = secsSinceEvent,
                    timestamp = timestamp,
                    displayName = displayName,
                    count = count,
                    itemLink = itemLink,
                    avgPrice = avgPrice,
                    item = GetItemLinkName(itemLink)
                }
        guildBankHistory[GuildBankEventsIndex] = data
    end

    PacsBankAddon.savedVariables.guildDepositList = guildBankHistory

    if enableDebug == true then
        d("Updated Saved Var Guild history with " .. numGuildBankEvents .. " events.")
    end
end


-- Update Guild Store History in Saved Variables
function PacsBankAddon.UpdateGuildStoreHistory()
    local activeGuildID = PacsBankAddon.savedVariables.activeGuildID
    local enableDebug = PacsBankAddon.savedVariables.enableDebug

    RequestGuildHistoryCategoryOlder(activeGuildID, GUILD_HISTORY_STORE)
    local numGuildStoreEvents = GetNumGuildEvents(activeGuildID, GUILD_HISTORY_STORE)
    local guildStoreHistory = {}
    for GuildStoreEventsIndex = 1, numGuildStoreEvents do
        local eventType, secsSinceEvent, param1, param2, param3, param4, param5, param6 = GetGuildEventInfo(activeGuildID, GUILD_HISTORY_STORE, GuildStoreEventsIndex)
        local timestamp = os.date("%m/%d/%Y %H:%M:%S %z", (os.time() - secsSinceEvent))

        if eventType == 15 then
            eventName = "Item Sold"
        elseif eventType == 41 then
            eventName = "Item Listed"
        elseif eventType == 24 then
            eventName = "Guild Trader Bid"
        else
            eventName = "Unknown"
        end

        local data = {
                    eventName = eventName,
                    eventType = eventType,
                    secsSinceEvent = secsSinceEvent,
                    timestamp = timestamp,
                    sellerName = param1,
                    buyerName = param2,
                    count = param3,
                    itemLink = param4,
                    sellPrice = param5,
                    guildCut = param6,
                    item = GetItemLinkName(param4)
                }
        guildStoreHistory[GuildStoreEventsIndex] = data
    end

    PacsBankAddon.savedVariables.guildStoreList = guildStoreHistory

    if enableDebug == true then
        d("Updated Saved Var Guild Store history with " .. numGuildStoreEvents .. " events.")
    end
end

-- Function to poll the server for Guild Bank History 100ish items at a time. 
function PacsBankAddon.LoadGuildHistoryBackfill()
    local activeGuildID = PacsBankAddon.savedVariables.activeGuildID
    local enableDebug = PacsBankAddon.savedVariables.enableDebug

    RequestGuildHistoryCategoryOlder(activeGuildID, GUILD_HISTORY_BANK)
    local moreEvents = (DoesGuildHistoryCategoryHaveMoreEvents(activeGuildID, GUILD_HISTORY_BANK))

    if moreEvents then
        moreEventsString = "Yes"
    else 
        moreEventsString = "No"
    end

    if enableDebug == true then
        d("Are there more guild bank history events to load? " .. moreEventsString)
        d("So far we have loaded " .. GetNumGuildEvents(activeGuildID, GUILD_HISTORY_BANK) .. " guild bank events")
    end

    -- If there are no more events to load lets stop checking every 2.5 seconds, and update our saved variables.
    if moreEvents == false then
        EVENT_MANAGER:UnregisterForUpdate("PacsUpdateGuildHistory")
        PacsBankAddon.UpdateGuildHistory()
    end
end


-- Function to poll the server for Guild Store History 100ish items at a time. 
function PacsBankAddon.LoadGuildStoreBackfill()
    local activeGuildID = PacsBankAddon.savedVariables.activeGuildID
    local enableDebug = PacsBankAddon.savedVariables.enableDebug

    RequestGuildHistoryCategoryOlder(activeGuildID, GUILD_HISTORY_STORE)
    local moreEvents = (DoesGuildHistoryCategoryHaveMoreEvents(activeGuildID, GUILD_HISTORY_STORE))

    if moreEvents then
        moreEventsString = "Yes"
    else 
        moreEventsString = "No"
    end

    if enableDebug == true then
        d("Are there more guild store history events to load? " .. moreEventsString)
        d("So far we have loaded " .. GetNumGuildEvents(activeGuildID, GUILD_HISTORY_STORE) .. " guild store events")
    end

    -- If there are no more events to load lets stop checking every 2.5 seconds, and update our saved variables.
    if moreEvents == false then
        EVENT_MANAGER:UnregisterForUpdate("PacsUpdateGuildStore")
        PacsBankAddon.UpdateGuildStoreHistory()
    end
end


-- Return Current Time
function PacsBankAddon.currentTimeShort()
    local time = os.date(" %I:%M:%S %p")
    PacsAddOnGUIClock:SetText(time)
    --d(time)
end


-- Search Table if string exist in it
function tablesearch(data, array)
    local valid = {}
    for i = 1, #array do
        valid[array[i]] = true
    end
    if valid[data] then
        return true
    else
        return false
    end
end



--  Settings Menu Function via LibAddonMenu-2.0
function PacsBankAddon.CreateSettingsWindow()
    local panelData = {
        type = "panel",
        name = "Pacrooti's Bank Tools",
        displayName = "Pacrooti's Bank Tools",
        author = "Erica Z",
        version = PacsBankAddon.version,
        slashCommand = "/pacsbanktools",
        registerForRefresh = true,
        registerForDefaults = true,
    }

    local cntrlOptionsPanel = LAM2:RegisterAddonPanel("PacsBankAddon_settings", panelData)

    guildNames = {}
    for guildIndex = 1, 5 do
        local guildID = GetGuildId(guildIndex)
        local guildName = GetGuildName(guildID)
        table.insert(guildNames, guildName)
    end


    local optionsData = {
        [1] = {
            type = "header",
            name = "Guild Selection",
        },

        [2] = {
            type = "dropdown",
            name = "Select active guild",
            tooltip = "The selected guild will be used for Bank History Export features.",
            choices = guildNames,
            getFunc = function() return PacsBankAddon.savedVariables.activeGuild end,
            setFunc = function(newValue) PacsBankAddon.savedVariables.activeGuild = newValue end,
        },

        [3] = {
            type = "header",
            name = "Raffle Settings",
        },

        [4] = {
            type = "header",
            name = "Guild Bank History",
        },

        [5] = {
            type = "checkbox",
            name = "Enable Export of Guild History",
            tooltip = "Save an Export of Guild Bank History to Saved Settings for use outside of ESO.",
            default = false,
            getFunc = function() return PacsBankAddon.savedVariables.enableBankExport end,
            setFunc = function(newValue) PacsBankAddon.savedVariables.enableBankExport = newValue end,
        },

        [6] = {
            type = "header",
            name = "Debug Messages",
        },

        [7] = {
            type = "checkbox",
            name = "Enable Debug Messages",
            default = false,
            getFunc = function() return PacsBankAddon.savedVariables.enableDebug end,
            setFunc = function(newValue) PacsBankAddon.savedVariables.enableDebug = newValue end,
        }
    }

    LAM2:RegisterOptionControls("PacsBankAddon_settings", optionsData)
 
end


EVENT_MANAGER:RegisterForEvent(PacsBankAddon.name, EVENT_ADD_ON_LOADED, PacsBankAddon.OnAddOnLoaded)