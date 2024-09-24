local skibidiPhrases = {
    "skibidi", "gigachad", "rizz", "on God", "for real", "no cap", "no cream",
    "on the dead homies", "gooning", "mewing", "edging", "my drilla", "bussy", 
    "glizzy", "gyatt", "GOAT", "lit", "mew", "mid", "ratio", "red flag", "salty",
    "sheesh", "shook", "simp", "slay", "sus", "tweaking", "Zesty"
}


local defaults = {
    enabled = true, 
}

local blockedChannelsDefaults = { "NewcomerChat" }


local db, blockedChannels, hyperlinks = {}, {}, {}


local function InitializeAddonDatabase()

    SkibidiSpeakDB = SkibidiSpeakDB or defaults
    SkibidiSpeakDBBlockedChannels = SkibidiSpeakDBBlockedChannels or blockedChannelsDefaults
    db, blockedChannels = SkibidiSpeakDB, SkibidiSpeakDBBlockedChannels
end


local function OnAddonLoaded(self, event, addon)
    if addon == "SkibidiSpeak" then
        InitializeAddonDatabase()
        self:UnregisterEvent("ADDON_LOADED")
    end
end


local function AddLinkToPlaceholder(link)
    table.insert(hyperlinks, link)
    return "link" .. #hyperlinks
end

local function RetrieveOriginalLink(placeholder)
    local index = tonumber(placeholder:match("%d+")) 
    return hyperlinks[index]
end


local function IsSkibidiSpeakAllowedInChannel(chatType, channel)
    if chatType == "CHANNEL" then
        local _, channelName = GetChannelName(channel)
        return not tContains(blockedChannels, channelName)
    end
    return true
end


local originalSendChatMessage = SendChatMessage
function SendChatMessage(msg, chatType, language, channel)
    if msg == "GHI2ChannelReadyCheck" then return end

    if db.enabled and IsSkibidiSpeakAllowedInChannel(chatType, channel) then
        hyperlinks = {}
        
        local messageWithLinks = msg:gsub("|c.-|r", AddLinkToPlaceholder):gsub("{.-}", AddLinkToPlaceholder)

        local words, newMessage = {}, ""
        for word in messageWithLinks:gmatch("%S+") do
            table.insert(words, word)
        end

        local wordCount = 0
        for _, word in ipairs(words) do
            newMessage = newMessage .. word .. " "
            wordCount = wordCount + 1
            if wordCount >= math.random(2, 4) then
                newMessage = newMessage .. skibidiPhrases[math.random(#skibidiPhrases)] .. " "
                wordCount = 0
            end
        end

        newMessage = strtrim(newMessage) 
        newMessage = (#newMessage <= 255 and newMessage:gsub("link%d+", RetrieveOriginalLink)) or msg
        originalSendChatMessage(newMessage, chatType, language, channel)
    else
        originalSendChatMessage(msg, chatType, language, channel)
    end
end

local EnabledMessages = {
    [true] = "|cffADDBB3Enabled On God No Cap|r",
    [false] = "|cffFF2424Disabled Cringe And Not Very Rizz|r",
}


local function PrintAddonMessage(msg)
    print("SkibidiSpeak: " .. msg)
end


local function ModifyBlockedChannels(action, channel)
    local actionText = action == "add" and "Added" or "Removed"
    
    if action == "add" then
        if not tContains(blockedChannels, channel) then
            table.insert(blockedChannels, channel)
            PrintAddonMessage(actionText .. " " .. channel .. " to the blocked channel list.")
        else
            PrintAddonMessage(channel .. " is already blocked.")
        end
    elseif action == "remove" then
        local index = FindIndexInTable(blockedChannels, channel)
        if index then
            table.remove(blockedChannels, index)
            PrintAddonMessage(actionText .. " " .. channel .. " from the blocked channels list.")
        else
            PrintAddonMessage("Could not find " .. channel .. " in the blocked channels list.")
        end
    end
end

SLASH_SKIBIDISPEAK1 = "/skibidi"
SLASH_SKIBIDISPEAK2 = "/skibidispeak"

SlashCmdList.SKIBIDISPEAK = function(msg)
    local cmd, param = msg:match("^(%S*)%s*(.-)$")

    if cmd == "add" and param ~= "" then
        ModifyBlockedChannels("add", param)
    elseif cmd == "remove" and param ~= "" then
        ModifyBlockedChannels("remove", param)
    elseif cmd == "blocked" then
        PrintAddonMessage("Currently blocked channels:")
        for _, value in pairs(blockedChannels) do print(value) end
    elseif cmd == "help" then
        PrintAddonMessage("Available commands:")
        print("|cffADDBB3/skibidi add <channel> - block skibidi speak in a specific channel|")
        print("|cffADDBB3/skibidi remove <channel> - unblock skibidi speak in a blocked channel|")
        print("|cffADDBB3/skibidi blocked - show blocked channels list|")
    else
        db.enabled = not db.enabled
        PrintAddonMessage(EnabledMessages[db.enabled])
    end
end

-- Event setup
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", OnAddonLoaded)
