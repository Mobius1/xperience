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

function Xperience:Load(src)
    if self.ready then
        local resp, result = false, false

        if Config.UseQBCore then
            local Player = QBCore.Functions.GetPlayer(src)
            if Player then
                result = {}
                result.xp = tonumber(Player.PlayerData.metadata.xp)
                result.rank = tonumber(Player.PlayerData.metadata.rank)
                
                resp = true
            end
        else
            local license = self:GetPlayerLicense(src)
            
            if Config.UseESX then
                MySQL.query('SELECT * FROM users WHERE license = ?', { license }, function(res)
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
                MySQL.query('SELECT * FROM user_experience WHERE identifier = ?', { license }, function(res)
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
        local license = self:GetPlayerLicense(src)
        if Config.UseESX then
            local Player = ESX.GetPlayerFromId(src)

            Player.set("xp", tonumber(xp))
            Player.set("rank", tonumber(rank))

            MySQL.update('UPDATE users SET xp = ?, rank = ? WHERE identifier = ?', { xp, rank, license }, function(affectedRows)
                if not affectedRows then
                    printError('There was a problem saving the user\'s data!')
                end
            end)
        else
            MySQL.update('UPDATE user_experience SET xp = ?, rank = ? WHERE identifier = ?', { xp, rank, license }, function(affectedRows)
                if not affectedRows then
                    printError('There was a problem saving the user\'s data!')
                end
            end)
        end
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
        local license = self:GetPlayerLicense(playerId)
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
        local license = self:GetPlayerLicense(playerId)
        local rank = MySQL.Sync.fetchScalar('SELECT rank FROM user_experience WHERE identifier = ?', { license })
    
        return tonumber(rank)
    end
end

function Xperience:GetPlayerLicense(src)
    local license = false

    for _, id in pairs(GetPlayerIdentifiers(src)) do
        if string.sub(id, 1, string.len('license:')) == 'license:' then
            if Config.UseESX then
                license = id
            else
                license = string.sub(id, 9, string.len(id))
            end
            break
        end
    end 
    
    return license
end

CreateThread(function() Xperience:Init() end)

RegisterNetEvent('xperience:server:load', function() Xperience:Load(source) end)
RegisterNetEvent('xperience:server:save', function(xp, rank) Xperience:Save(source, xp, rank) end)

exports('GetPlayerXP', function(playerID) return Xperience:GetPlayerXP(playerID) end)
exports('GetPlayerRank', function(playerID) return Xperience:GetPlayerRank(playerID) end)
