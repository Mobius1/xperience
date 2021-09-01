local Xperience = {}

function Xperience:Init()
    self.Ready = false

    exports.ghmattimysql:execute('CREATE TABLE IF NOT EXISTS `user_experience` (`identifier` varchar(40) NOT NULL, `xp` int(11) DEFAULT 0, `rank` int(11) DEFAULT 1, UNIQUE KEY `unique_identifier` (`identifier`)) ENGINE=InnoDB DEFAULT CHARSET=latin1;', {}, function(res)
        self.Ready = true
    end)
end

function Xperience:Load(src)
    while not self.Ready do Citizen.Wait(0) end

    local identifier = self:GetPlayerID(src)
    local resp, result = false, false

    if identifier then
        exports.ghmattimysql:execute('SELECT * FROM user_experience WHERE identifier = @identifier', {
            ['@identifier'] = identifier,
        }, function(res)
            if #res == 0 then
                exports.ghmattimysql:execute('INSERT INTO user_experience (identifier) VALUES (@identifier)', {
                    ['@identifier'] = identifier,
                }, function(res)
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
    while not self.Ready do Citizen.Wait(0) end

    local identifier = self:GetPlayerID(src)

    if identifier then
        exports.ghmattimysql:execute('UPDATE user_experience SET xp = @xp, rank = @rank WHERE identifier = @identifier', {
            ['@xp'] = xp,
            ['@rank'] = rank,
            ['@identifier'] = identifier,
        }, function(res)
            print('saved', xp, rank)
        end)
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