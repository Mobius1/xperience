local MySQLReady, QBCore, ESX = false, nil, nil
local Xperience = {}

MySQL.ready(function()
    MySQLReady = true
end)

function Xperience:Init()
    while not MySQLReady do Wait(5) end

    self.ready = false

    local Ranks = self:CheckRanks()
    
    if #Ranks > 0 then
        PrintTable(Ranks)
        return
    end

    if Config.UseQBCore and Config.UseESX then
        return printError("You can't use QBCore and ESX together!")
    end

    if Config.UseQBCore then
        local status = GetResourceState('qb-core')
        if status ~= 'started' then
            return printError(string.format('QBCORE is %s!', status))
        end

        QBCore = exports['qb-core']:GetCoreObject()
    elseif Config.UseESX then
        local status = GetResourceState('es_extended')
        if status ~= 'started' then
            return printError(string.format('ESX is %s!', status))
        end

        ESX = exports['es_extended']:getSharedObject()
    end

    self.ready = true
end

function Xperience:Load(src)
    src = tonumber(src)

    if self.ready then
        local resp, result = false, false

        if Config.UseQBCore then
            local Player = QBCore.Functions.GetPlayer(src)
            if Player then
                result = {}
                result.xp = tonumber(Player.PlayerData.metadata.xp) or 0
                result.rank = tonumber(Player.PlayerData.metadata.rank) or 1
                
                resp = true
            end
        else
            local license = self:GetPlayer(src)
            
            if Config.UseESX then
                local statement = 'SELECT * FROM users WHERE license = @license'

                if Config.ESXIdentifierColumn == 'identifier' then
                    statement = 'SELECT * FROM users WHERE identifier = @license'
                end
                
                MySQL.Async.fetchAll(statement, { ['@license'] = license }, function(res)
                    if res[1] then
                        result = {}
                        result.xp = tonumber(res[1].xp)
                        result.rank = tonumber(res[1].rank)

                        local Player = ESX.GetPlayerFromId(src)
                        Player.set("xp", result.xp)
                        Player.set("rank", result.rank)

                        resp = true
                    end
                end)
            else
                MySQL.Async.fetchAll('SELECT * FROM user_experience WHERE identifier = ?', { license }, function(res)
                    if res[1] then
                        result = {}
                        result.xp = tonumber(res[1].xp)
                        result.rank = tonumber(res[1].rank)

                        resp = true
                    end
                end)
            end
        end

        while not resp do Wait(0) end

        if Config.Debug then
            print(string.format("^5LOADED DATA FOR PLAYER: %s (XP %s, Rank %s)^7", GetPlayerName(src), result.xp, result.rank))
        end

        TriggerClientEvent('xperience:client:init', src, result)
    end
end

function Xperience:Save(src, xp, rank)
    if Config.UseQBCore then
        local Player = QBCore.Functions.GetPlayer(src)

        Player.Functions.SetMetaData('xp', tonumber(xp))
        Player.Functions.SetMetaData('rank', tonumber(rank))
        Player.Functions.Save()
    else
        local license = self:GetPlayer(src)
        if Config.UseESX then
            local Player = ESX.GetPlayerFromId(src)

            Player.set("xp", tonumber(xp))
            Player.set("rank", tonumber(rank))

            MySQL.Async.execute('UPDATE users SET xp = ?, rank = ? WHERE identifier = ?', { xp, rank, license }, function(affectedRows)
                if not affectedRows then
                    printError('There was a problem saving the user\'s data!')
                end
            end)
        else
            MySQL.Async.execute('UPDATE user_experience SET xp = ?, rank = ? WHERE identifier = ?', { xp, rank, license }, function(affectedRows)
                if not affectedRows then
                    printError('There was a problem saving the user\'s data!')
                end
            end)
        end
    end

    if Config.Debug then
        print(string.format("^5SAVED DATA FOR PLAYER: %s (XP %s, Rank %s)^7", GetPlayerName(src), xp, rank))
    end
end

function Xperience:GetPlayerXP(playerId)
    if Config.UseQBCore then
        local Player = QBCore.Functions.GetPlayer(playerId)

        if Player then
            return Player.PlayerData.metadata.xp
        end
    elseif Config.UseESX then
        local Player = ESX.GetPlayerFromId(playerId)

        if Player then
            return tonumber(Player.get("xp"))
        end
    else
        local license = self:GetPlayer(playerId)
        local xp = MySQL.Sync.fetchScalar('SELECT xp FROM user_experience WHERE identifier = ?', { license })

        return tonumber(xp)
    end

    return false
end

function Xperience:GetPlayerRank(playerId)
    if Config.UseQBCore then
        local Player = QBCore.Functions.GetPlayer(playerId)

        if Player then
            return Player.PlayerData.metadata.rank
        end
    elseif Config.UseESX then
        local Player = ESX.GetPlayerFromId(playerId)
    
        if Player then
            return tonumber(Player.get("rank"))
        end
    else
        local license = self:GetPlayer(playerId)
        local rank = MySQL.Sync.fetchScalar('SELECT rank FROM user_experience WHERE identifier = ?', { license })
    
        return tonumber(rank)
    end
end

function Xperience:GetPlayerXPToNextRank(playerId)
    local currentXP = self:GetPlayerXP(playerId)
    local currentRank = self:GetPlayerRank(playerId)

    return tonumber(Config.Ranks[currentRank + 1].XP) - tonumber(currentXP)   
end

function Xperience:GetPlayerXPToRank(playerId, rank)
    local currentXP = self:GetPlayerXP(playerId)
    local rank = tonumber(rank)

    -- Check for valid rank
    if not rank or (rank < 1 or rank > #Config.Ranks) then
        printError('Invalid rank ('.. rank ..') passed to GetPlayerXPToRank method')
        return
    end

    local goalXP = tonumber(Config.Ranks[rank].XP)

    return goalXP - currentXP
end

function Xperience:GetPlayer(src)
    for _, id in pairs(GetPlayerIdentifiers(src)) do
        if string.sub(id, 1, string.len('license:')) == 'license:' then
            if Config.UseESX and Config.ESXIdentifierColumn == 'license' then
                return id
            end

            return string.sub(id, 9, string.len(id))
        end
    end 
    
    return false
end

function Xperience:CheckRanks()
    local Limit = #Config.Ranks
    local InValid = {}

    for i = 1, Limit do
        local RankXP = Config.Ranks[i].XP

        if not isInt(RankXP) then
            table.insert(InValid, string.format('Rank %s: %s', i,  RankXP))
            printError(string.format('Invalid XP (%s) for Rank %s', RankXP, i))
        end
        
    end

    return InValid
end

function Xperience:RunCommand(src, type, args)
    local playerId = tonumber(args[1])
    local value = tonumber(args[2])
    
    if playerId ~= nil and value ~= nil then
        local player = self:GetPlayer(playerId)
    
        if not player then
            return self:PrintError(src, 'Player is offline')
        end
    
        TriggerClientEvent('xperience:client:' .. type, playerId, value)
    end

    if Config.Debug then
        if src ~= 0 then
            print(string.format("^5PLAYER %s EXECUTED COMMAND %s^7", GetPlayerName(src), type))
        end
    end
end

function Xperience:Notify(src, message, type)
    if Config.UseQBCore then
        TriggerClientEvent('QBCore:Notify', src, message, type)
    elseif Config.UseESX then
        TriggerClientEvent('esx:showNotification', src, message)
    end  
end

function Xperience:Restart()
    CreateThread(function()
        for i, src in pairs(GetPlayers()) do
            self:Load(src)
        end
    end)
end

function Xperience:PrintError(src, message)
    if src > 0 then
        TriggerClientEvent('chat:addMessage', src, {
            color = { 255, 0, 0 },
            args = { "xperience", message }
        })

        self:Notify(src, message, 'error')
    else
        print(string.format("^1%s^7", message))
    end
end

CreateThread(function() Xperience:Init() end)


----------------------------------------------------
--                 EVENT HANDLERS                 --
----------------------------------------------------

RegisterNetEvent('xperience:server:load', function() Xperience:Load(source) end)
RegisterNetEvent('xperience:server:save', function(xp, rank) Xperience:Save(source, xp, rank) end)


----------------------------------------------------
--                    EXPORTS                     --
----------------------------------------------------

exports('GetPlayerXP', function(playerId) return Xperience:GetPlayerXP(playerId) end)
exports('GetPlayerRank', function(playerId) return Xperience:GetPlayerRank(playerId) end)
exports('GetPlayerXPToRank', function(playerId, rank) return Xperience:GetPlayerXPToRank(playerId, rank) end)
exports('GetPlayerXPToNextRank', function(playerId) return Xperience:GetPlayerXPToNextRank(playerId) end)


----------------------------------------------------
--                   COMMANDS                     --
----------------------------------------------------

-- Requires ace permissions: e.g. add_ace group.admin command.addXP allow

-- Allows for restarting the resource
RegisterCommand('restartXP', function(source, args) Xperience:Restart() end, true)

-- Award XP to player
RegisterCommand('addXP', function(source, args) Xperience:RunCommand(source, 'addXP', args) end, true)

-- Deduct XP from player
RegisterCommand('removeXP', function(source, args) Xperience:RunCommand(source, 'removeXP', args) end, true)

-- Set a player's XP
RegisterCommand('setXP', function(source, args) Xperience:RunCommand(source, 'setXP', args) end, true)

-- Set a player's rank
RegisterCommand('setRank', function(source, args) Xperience:RunCommand(source, 'setRank', args) end, true)
