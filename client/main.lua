local Xperience = {}

if Config.UseESX then
    AddEventHandler('esx:playerLoaded', function()
        TriggerServerEvent('xperience:server:load')
    end)
elseif Config.UseQBCore then
    AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
        TriggerServerEvent('xperience:server:load')
    end)
else
    AddEventHandler("playerSpawned", function()
        TriggerServerEvent('xperience:server:load')
    end)
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
end

function Xperience:Load()
    TriggerServerEvent('xperience:server:load')
end


----------------------------------------------------
--                 EVENT CALLBACKS                --
----------------------------------------------------

function Xperience:OnRankChange(data, cb)
    if data.rankUp then
        TriggerEvent("experience:client:rankUp", data.current, data.previous)
    else
        TriggerEvent("experience:client:rankDown", data.current, data.previous)      
    end
        
    local Rank = Config.Ranks[data.current]
    
    if Rank.Action ~= nil and type(Rank.Action) == "function" then
        Rank.Action(data.rankUp, data.previous)
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
        xperience_init = true,
        xperience_xp = self:GetXP(),
        xperience_ranks = ranks,
        xperience_width = Config.Width,
        xperience_timeout = Config.Timeout,
        xperience_segments = Config.BarSegments,         
    })
end

function Xperience:OpenUI()
    self.UIOpen = true
    SendNUIMessage({ xperience_show = true })
end

function Xperience:CloseUI()
    self.UIOpen = false
    SendNUIMessage({ xperience_hide = true })
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
        xperience_add = true,
        xperience_xp = xp      
    })
end

function Xperience:RemoveXP(xp)
    if not isInt(xp) then
        return
    end

    local newXP = self:GetXP() - xp

    self:SetData(newXP)

    SendNUIMessage({
        xperience_remove = true,
        xperience_xp = xp      
    })
end

function Xperience:SetXP(xp)
    if not isInt(xp) then
        return
    end
    
    self:SetData(xp)
    
    SendNUIMessage({
        xperience_set = true,
        xperience_xp = xp      
    })
end

function Xperience:SetRank(rank)
    rank = tonumber(rank)

    if not rank then
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

    return Config.Ranks[currentRank + 1].XP - tonumber(self.CurrentXP)   
end

function Xperience:GetXPToRank(rank)
    local GoalRank = tonumber(rank)
    -- Check for valid rank
    if not GoalRank or (GoalRank < 1 or GoalRank > #Config.Ranks) then
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

function Xperience:PrintError(message)
    local out = string.format('^1%s Error: ^7%s', GetCurrentResourceName(), message)
    local s = string.rep("=", string.len(out))
    print('^1' .. s)
    print(out)
    print('^1' .. s)  
end


----------------------------------------------------
--                 EVENT HANDLERS                 --
----------------------------------------------------

AddEventHandler('playerSpawned', function(...) Xperience:Load(...) end)

RegisterNetEvent('xperience:client:init')
AddEventHandler('xperience:client:init', function(...) Xperience:Init(...) end)

RegisterNetEvent('xperience:client:addXP')
AddEventHandler('xperience:client:addXP', function(...) Xperience:AddXP(...) end)

RegisterNetEvent('xperience:client:removeXP')
AddEventHandler('xperience:client:removeXP', function(...) Xperience:RemoveXP(...) end)

RegisterNetEvent('xperience:client:setXP')
AddEventHandler('xperience:client:setXP', function(...) Xperience:SetXP(...) end)

RegisterNetEvent('xperience:client:setRank')
AddEventHandler('xperience:client:setRank', function(...) Xperience:SetRank(...) end)

RegisterNUICallback('xperience_rankchange', function(...) Xperience:OnRankChange(...) end)
RegisterNUICallback('xperience_ui_initialised', function(...) Xperience:OnUIInitialised(...) end)
RegisterNUICallback('xperience_ui_closed', function(...) Xperience:OnUIClosed(...) end)
RegisterNUICallback('xperience_save', function(...) Xperience:OnSave(...) end)


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
