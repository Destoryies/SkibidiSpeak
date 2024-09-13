local skibidiPhrases = {
    "Skibidi",
    "Gigachad",
    "Rizz",
    "On God",
    "For Real",
    "No Cap",
    "No Cream",
    "On The Dead Homies",
    "Gooning",
    "Mewing",
    "Edging",
    "My Drilla",
    "Bussy",
    "Glizzy",
    "Gyatt",
    "GOAT",
    "Karen",
    "Lit",
    "Mew",
    "Mid",
    "OK Boomer",
    "Oof",
    "Opp",
    "Pookie",
    "Ratio",
    "Red Flag",
    "Salty",
    "Sheesh",
    "Shook",
    "Simp",
    "Slay",
    "Sus",
    "Tweaking",
    "Valid",
    "Vibe",
    "Yeet",
    "Zesty",
}


 
local defaults = {
    enabled = true,
    guild = true,
    officer = true,
    whisper = true,
}
 
local blockedChannelsDefaults = {
    "NewcomerChat",
}
 
local db
local blockedChannels
local hyperlinks = {}
 
local function OnEvent(self, event, addon)
    if addon == "SkibidiSpeak" then
        SkibidiSpeakDB = SkibidiSpeakDB or CopyTable(defaults)
        SkibidiSpeakDBBlockedChannels = SkibidiSpeakDBBlockedChannels or CopyTable(blockedChannelsDefaults)
        blockedChannels = SkibidiSpeakDBBlockedChannels
        db = SkibidiSpeakDB
        for k, v in pairs(defaults) do
            if db[k] == nil then
                db[k] = v
            end
        end
        self:UnregisterEvent("ADDON_LOADED")
    end
end
 
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", OnEvent)
 
-- Replace links with placeholders
local function ReplaceLink(s)
    tinsert(hyperlinks, s)
    return "link"..#hyperlinks
end
 
local function RestoreLink(s)
    local n = tonumber(s:match("%d"))
    return hyperlinks[n]
end
 
local channelOptions = {
    GUILD = function() return db.guild end,
    OFFICER = function() return db.officer end,
    WHISPER = function() return db.whisper end,
}
 
local function ShouldApplySkibidi(chatType)
    if db.enabled then
        if channelOptions[chatType] then
            return channelOptions[chatType]()
        else
            return true
        end
    end
end
 
local function ShouldApplySkibidiToChannel(chatType, channel)
    if chatType == "CHANNEL" then
        local id, channelName = GetChannelName(channel)
        for key, value in pairs(blockedChannels) do
            if channelName == value then
                return false
            end
        end
    end
    return true
end
 
local originalSendChatMessage = SendChatMessage
 
function SendChatMessage(msg, chatType, language, channel)
    if msg == "GHI2ChannelReadyCheck" then
        return
    end
    if ShouldApplySkibidi(chatType) and ShouldApplySkibidiToChannel(chatType, channel) then
        wipe(hyperlinks)
        local s = msg:gsub("|c.-|r", ReplaceLink)
        s = s:gsub("{.-}", ReplaceLink)
        
        -- Split the message into words
        local words = {}
        for word in s:gmatch("%S+") do
            table.insert(words, word)
        end

        -- Insert random skibidi phrases every few words
        local newMessage = ""
        local wordCount = 0
        for i, word in ipairs(words) do
            newMessage = newMessage .. word .. " "
            wordCount = wordCount + 1
            if wordCount >= random(2, 4) then  -- Insert a skibidi phrase every 2 to 4 words randomly
                local randomPhrase = skibidiPhrases[random(#skibidiPhrases)]
                newMessage = newMessage .. randomPhrase .. " "
                wordCount = 0
            end
        end

        newMessage = newMessage:trim()
        newMessage = #newMessage <= 255 and newMessage:gsub("link%d", RestoreLink) or msg
        originalSendChatMessage(newMessage, chatType, language, channel)
    else
        originalSendChatMessage(msg, chatType, language, channel)
    end
end
 
local EnabledMsg = {
    [true] = "|cffADFF2FEnabled|r",
    [false] = "|cffFF2424Disabled|r",
}
 
local function PrintMessage(msg)
    print("SkibidiSpeak: "..msg)
end
 
SLASH_SKIBIDISPEAK1 = "/skibidi"
SLASH_SKIBIDISPEAK2 = "/skibidipeak"
 
local function tablefind(tab, el)
    for index, value in pairs(tab) do
        if value == el then
            return index
        end
    end
end
 
SlashCmdList.SKIBIDISPEAK = function(msg)
    if msg == "guild" then
        db.guild = not db.guild
        PrintMessage("Guild - "..EnabledMsg[db.guild])
    elseif msg == "officer" then
        db.officer = not db.officer
        PrintMessage("Officer - "..EnabledMsg[db.officer])
    elseif msg == "whisper" then
        db.whisper = not db.whisper
        PrintMessage("Whisper - "..EnabledMsg[db.whisper])
    elseif string.find(msg, "add") then
        local exploded = {}
        for substring in string.gmatch(msg, "[^%s]+") do
            table.insert(exploded, substring)
        end
        if exploded[2] then
            table.insert(blockedChannels, exploded[2])
            PrintMessage("Added " .. exploded[2] .. " to the blocked channel list.")
        else
            PrintMessage("You must provide a channel name to block.")
        end
    elseif string.find(msg, "remove") then
        local exploded = {}
        local foundAndRemoved = false
        for substring in string.gmatch(msg, "[^%s]+") do
            table.insert(exploded, substring)
        end
        if exploded[2] then
            for key, value in pairs(blockedChannels) do
                if value == exploded[2] then
                    PrintMessage("Removed " .. exploded[2] .. " from the blocked channels list.")
                    table.remove(blockedChannels, tablefind(blockedChannels, exploded[2]))
                    foundAndRemoved = true
                end
            end
            if not foundAndRemoved then
                PrintMessage("Could not find the specified channel in the blocked channels list.")
            end
        else
            PrintMessage("You must provide a channel name to unblock.")
        end
    elseif msg == "blocked" then
        PrintMessage("Currently blocked channels:")
        for key, value in pairs(blockedChannels) do
            print(value)
        end
    elseif msg == "help" then
        PrintMessage("Available commands:")
        print("/skibidi guild - enable/disable guild chat skibidi speak")
        print("/skibidi officer - enable/disable officer chat skibidi speak")
        print("/skibidi whisper - enable/disable whisper skibidi speak")
        print("/skibidi add <channel name> - prevent skibidi speak in a specific channel")
        print("/skibidi remove <channel name> - re-enable skibidi speak in a blocked channel (see /skibidi add)")
        print("/skibidi blocked - print list of currently blocked channels")
    else
        db.enabled = not db.enabled
        PrintMessage(EnabledMsg[db.enabled])
    end
end
 
