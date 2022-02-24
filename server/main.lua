local Xperience = {}

function Xperience:Load(src)
    local identifier = self:GetPlayerID(src)
    local resp, result = false, false

    if identifier then
        MySQL.query('SELECT * FROM user_experience WHERE identifier = ?', {  identifier }, function(res)
            if #res == 0 then
                MySQL.Sync.execute('INSERT INTO user_experience (identifier) VALUES (?)', { identifier }, function(res)
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

    while not resp do Citizen.Wait(0) end

    TriggerClientEvent('xperience:client:init', src, result)   
end

function Xperience:Save(src, xp, rank)
    local identifier = self:GetPlayerID(src)

    if identifier then
        MySQL.Sync.update('UPDATE user_experience SET xp = ?, rank = ? WHERE identifier = ?', { xp, rank, identifier })
    end
end

function Xperience:GetPlayerID(src)
    for k, v in pairs(GetPlayerIdentifiers(src))do
        if string.sub(v, 1, string.len('license:')) == 'license:' then
            return string.sub(v, 9, string.len(v))
        end
    end 
    
    return false
end

Citizen.CreateThread(function(...) Xperience:Init(...) end)

RegisterNetEvent('xperience:server:load')
AddEventHandler('xperience:server:load', function(...) Xperience:Load(source, ...) end)

RegisterNetEvent('xperience:server:save')
AddEventHandler('xperience:server:save', function(...) Xperience:Save(source, ...) end)