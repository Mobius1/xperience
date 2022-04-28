local Xperience = {}
local event = 'playerSpawned'

if Config.UseESX then
    event = 'esx:playerLoaded'
elseif Config.UseQBCore then
    event = 'QBCore:Client:OnPlayerLoaded'
end

function Xperience:Init(data)
    self.CurrentXP      = tonumber(data.xp)
    self.CurrentRank    = tonumber(data.rank)

    self:InitialiseUI()

    RegisterCommand('+xperience', function()
        if self.Initialised then
            self:ToggleUI()
        end
    end)
    RegisterCommand('-xperience', function() end)
    RegisterKeyMapping('+xperience', 'Show Rank Bar', 'keyboard', Config.UIKey)

    TriggerEvent('chat:addSuggestion', '/addXP', 'Give XP to player', {
        { name = "playerId",    help = 'The player\'s ID' },
        { name = "xp",          help = 'The XP value to award' }
    })

    TriggerEvent('chat:addSuggestion', '/removeXP', 'Deduct XP from player', {
        { name = "playerId",    help = 'The player\'s ID' },
        { name = "xp",          help = 'The XP value to deduct' }
    })

    TriggerEvent('chat:addSuggestion', '/setXP', 'Set a player\'s current XP', {
        { name = "playerId",    help = 'The player\'s ID' },
        { name = "xp",          help = 'The XP value to set' }
    })   
    
    TriggerEvent('chat:addSuggestion', '/setRank', 'Set a player\'s current rank', {
        { name = "playerId",    help = 'The player\'s ID' },
        { name = "rank",        help = 'The rank value to set' }
    })      
end


----------------------------------------------------
--                 EVENT CALLBACKS                --
----------------------------------------------------

function Xperience:OnRankChange(data, cb)
    local player = PlayerPedId()
    local current = tonumber(data.current)
    local previous = tonumber(data.previous)

    if data.rankUp then
        TriggerEvent("experience:client:rankUp", current, previous, player)
        TriggerServerEvent("experience:server:rankUp", current, previous)
    else
        TriggerEvent("experience:client:rankDown", current, previous, player)
        TriggerServerEvent("experience:server:rankDown", current, previous)   
    end
        
    local Rank = Config.Ranks[current]
    if Rank.Action ~= nil and type(Rank.Action) == "function" then
        Rank.Action(data.rankUp, previous, player)
    end
    
    cb('ok')
end

function Xperience:OnUIInitialised(data, cb)
    self.Initialised = true
    self.UIOpen = false

    cb('ok')
end

function Xperience:OnSave(data, cb)
    self:SetData(data.xp)

    TriggerServerEvent('xperience:server:save', self.CurrentXP, self.CurrentRank)

    cb('ok')
end

function Xperience:OnUIClosed(data, cb)
    self.UIOpen = false
    cb('ok')
end


----------------------------------------------------
--                       UI                       --
----------------------------------------------------

function Xperience:InitialiseUI()
    local ranks = self:GetRanksForUI()

    SendNUIMessage({
        init = true,
        xp = self:GetXP(),
        ranks = ranks,
        width = Config.Width,
        timeout = Config.Timeout,
        segments = Config.BarSegments,         
    })
end

function Xperience:OpenUI()
    self.UIOpen = true
    SendNUIMessage({ show = true })
end

function Xperience:CloseUI()
    self.UIOpen = false
    SendNUIMessage({ hide = true })
end

function Xperience:ToggleUI()
    if self.UIOpen then
        self:CloseUI()
    else
        self:OpenUI()
    end
end

----------------------------------------------------
--                    SETTERS                     --
----------------------------------------------------

function Xperience:AddXP(xp)
    if not isInt(xp) then
        return
    end

    self:SetData(xp)

    SendNUIMessage({
        add = true,
        xp = xp      
    })
end

function Xperience:RemoveXP(xp)
    if not isInt(xp) then
        return
    end

    local newXP = self:GetXP() - xp

    self:SetData(newXP)

    SendNUIMessage({
        remove = true,
        xp = xp      
    })
end

function Xperience:SetXP(xp)
    if not isInt(xp) then
        return
    end
    
    self:SetData(xp)
    
    SendNUIMessage({
        set = true,
        xp = xp      
    })
end

function Xperience:SetRank(rank)
    rank = tonumber(rank)

    if not rank or not Config.Ranks[rank] then
        printError('Invalid rank (' .. tostring(rank) .. ') passed to SetRank method')
        return
    end

    local newXP = Config.Ranks[rank].XP

    if newXP ~= nil then
        if newXP > self.CurrentXP then
            self:AddXP(newXP - self.CurrentXP)
        elseif newXP < self.CurrentXP then
            self:RemoveXP(self.CurrentXP - newXP)
        end
    end
end

function Xperience:SetData(xp)
    self.CurrentXP = self:LimitXP(xp)
    self.CurrentRank = self:GetRank(xp)
end


----------------------------------------------------
--                    GETTERS                     --
----------------------------------------------------

function Xperience:GetXP()
    return tonumber(self.CurrentXP)
end

function Xperience:GetMaxXP()
    return Config.Ranks[#Config.Ranks].XP
end

function Xperience:GetXPToNextRank()
    local currentRank = self:GetRank()

    if currentRank == #Config.Ranks then
        return 0
    end

    return Config.Ranks[currentRank + 1].XP - tonumber(self.CurrentXP)   
end

function Xperience:GetXPToRank(rank)
    local GoalRank = tonumber(rank)
    -- Check for valid rank
    if not Config.Ranks[rank] or not GoalRank or (GoalRank < 1 or GoalRank > #Config.Ranks) then
        printError('Invalid rank ('.. GoalRank ..') passed to GetXPToRank method')
        return
    end

    local goalXP = tonumber(Config.Ranks[GoalRank].XP)

    return goalXP - self.CurrentXP
end

function Xperience:GetRank(xp)
    if xp == nil then
        return tonumber(self.CurrentRank)
    end

    local len = #Config.Ranks
    for rank = 1, len do
        if rank < len then
            if Config.Ranks[rank + 1].XP > tonumber(xp) then
                return rank
            end
        else
            return rank
        end
    end
end

function Xperience:GetMaxRank()
    return #Config.Ranks
end


----------------------------------------------------
--                    UTILITIES                   --
----------------------------------------------------
function Xperience:GetRanksForUI()
    local ranks = {}
    local len = #Config.Ranks

    for i = 1, len do
        ranks[i] = Config.Ranks[i].XP
    end

    return ranks
end

-- Prevent XP from going over / under limits
function Xperience:LimitXP(xp)
    local Max = tonumber(Config.Ranks[#Config.Ranks].XP)

    if xp > Max then
        xp = Max
    elseif xp < 0 then
        xp = 0
    end

    return xp
end


----------------------------------------------------
--                 EVENT HANDLERS                 --
----------------------------------------------------

AddEventHandler(event, function() TriggerServerEvent('xperience:server:load') end)

RegisterNetEvent('xperience:client:init', function(...) Xperience:Init(...) end)
RegisterNetEvent('xperience:client:addXP', function(...) Xperience:AddXP(...) end)
RegisterNetEvent('xperience:client:removeXP', function(...) Xperience:RemoveXP(...) end)
RegisterNetEvent('xperience:client:setXP', function(...) Xperience:SetXP(...) end)
RegisterNetEvent('xperience:client:setRank', function(...) Xperience:SetRank(...) end)

RegisterNUICallback('rankchange', function(...) Xperience:OnRankChange(...) end)
RegisterNUICallback('ui_initialised', function(...) Xperience:OnUIInitialised(...) end)
RegisterNUICallback('ui_closed', function(...) Xperience:OnUIClosed(...) end)
RegisterNUICallback('save', function(...) Xperience:OnSave(...) end)


----------------------------------------------------
--                    EXPORTS                     --
----------------------------------------------------

exports('AddXP', function(...) return Xperience:AddXP(...) end)
exports('RemoveXP', function(...) return Xperience:RemoveXP(...) end)
exports('SetXP', function(...) return Xperience:SetXP(...) end)
exports('SetRank', function(...) return Xperience:SetRank(...) end)

exports('GetXP', function(...) return Xperience:GetXP(...) end)
exports('GetMaxXP', function(...) return Xperience:GetMaxXP(...) end)
exports('GetXPToRank', function(...) return Xperience:GetXPToRank(...) end)
exports('GetXPToNextRank', function(...) return Xperience:GetXPToNextRank(...) end)
exports('GetRank', function(...) return Xperience:GetRank(...) end)
exports('GetMaxRank', function(...) return Xperience:GetMaxRank(...) end)
