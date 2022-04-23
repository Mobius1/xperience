local QBCore, ESX = nil, nil
local Xperience = {}

function Xperience:Init()
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
        local identifier = self:GetPlayerID(src)
        local resp, result = false, false

        if identifier then
            MySQL.query('SELECT * FROM user_experience WHERE identifier = ?', {  identifier }, function(res)
                if #res == 0 then
                    MySQL.Async.execute('INSERT INTO user_experience (identifier) VALUES (?)', { identifier }, function(res)
                        result = {
                            identifier = identifier,
                            xp = 0,
                            rank = 1
                        }
                        resp = true
                    end)
                else
                    result = res[1]
                    resp = true
                end
            end)
        else
            resp = true
            result = false
        end

        while not resp do Wait(0) end

        if Config.UseQBCore then
            local Player = QBCore.Functions.GetPlayer(src)

            Player.Functions.SetMetaData('xp', tonumber(result.xp))
            Player.Functions.SetMetaData('rank', tonumber(result.rank))
        elseif Config.UseESX then
            local Player = ESX.GetPlayerFromId(src)

            Player.set("xp", tonumber(result.xp))
            Player.set("rank", tonumber(result.rank))
        end

        TriggerClientEvent('xperience:client:init', src, result)
    end
end

function Xperience:Save(src, xp, rank)
    local identifier = self:GetPlayerID(src)

    if identifier then
        if Config.UseQBCore then
            local Player = QBCore.Functions.GetPlayer(src)

            Player.Functions.SetMetaData('xp', tonumber(xp))
            Player.Functions.SetMetaData('rank', tonumber(rank))
        elseif Config.UseESX then
            local Player = ESX.GetPlayerFromId(src)

            Player.set("xp", tonumber(xp))
            Player.set("rank", tonumber(rank))
        end

        MySQL.Sync.update('UPDATE user_experience SET xp = ?, rank = ? WHERE identifier = ?', { xp, rank, identifier })
    end
end

function Xperience:GetPlayerID(src)
    local license = false

    for k, v in pairs(GetPlayerIdentifiers(src))do
        if string.sub(v, 1, string.len('license:')) == 'license:' then
            license = string.sub(v, 9, string.len(v))
            break
        end
    end 
    
    return license
end

CreateThread(function() Xperience:Init() end)

RegisterNetEvent('xperience:server:load', function() Xperience:Load(source) end)
RegisterNetEvent('xperience:server:save', function(xp, rank) Xperience:Save(source, xp, rank) end)