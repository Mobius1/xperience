# xperience
XP Ranking System for FiveM


* Designed to emulate the native GTA:O system
* Saves and loads players XP / rank
* Add / remove XP from your own script / job
* Allows you listen for rank changes to reward players
* Fully customisable UI
* Framework agnostic, but supports `ESX` and `QBCore`


##### Increasing XP

![Demo Image 1](https://i.imgur.com/CpACt9s.gif)

##### Rank Up

![Demo Image 2](https://i.imgur.com/uNPRGo5.gif)

# STILL UNDER DEVELOPMENT

## Table of Contents
- [Install](#install)
- [Transitioning from esx_xp](#transitioning-from-esx_xp)
- [Usage](#usage)
  * [Client](#client)
  * [Server](#server)
- [Rank Events](#rank-events)
- [Rank Actions](#rank-actions)
- [QBCore Integration](#qbcore-integration)
- [FAQ](#faq)
 
## Install
* If you want to use `xperience` as a standalone resource then import `xperience_standalone.sql` only
* If using `ESX` with `Config.UseESX` set to `true` then import `xperience_esx.sql` only. This adds the `xp` and `rank` columns to the `users` table
* If using `QBCore` with `Config.UseQBCore` set to `true` then there's no need to import any `sql` files as the xp and rank are saved to the player's metadata - see [QBCore Integration](#qbcore-integration)
* Drop the `xperience` directory into you `resources` directory
* Add `ensure xperience` to your `server.cfg` file

By default this resource uses `oxmysql`, but if you don't want to use / install it then you can use `mysql-async` by following these instructions:

* Uncomment the `'@mysql-async/lib/MySQL.lua',` line in `fxmanifest.lua` and comment out the `'@oxmysql/lib/MySQL.lua'` line

## Transitioning from esx_xp
* Rename the `rp_xp` column in the `users` table to `xp`
* Rename the `rp_rank` column in the `users` table to `rank`

## Usage

### Client Side

#### Exports
Give XP to player
```lua
exports.xperience:AddXP(xp --[[ integer ]])
```

Take XP from player
```lua
exports.xperience:RemoveXP(xp --[[ integer ]])
```

Set player's XP
```lua
exports.xperience:SetXP(xp --[[ integer ]])
```

Set player's rank
```lua
exports.xperience:SetRank(rank --[[ integer ]])
```

Get player's XP
```lua
exports.xperience:GetXP()
```

Get player's rank
```lua
exports.xperience:GetRank()
```

Get XP required to rank up
```lua
exports.xperience:GetXPToNextRank()
```

Get XP required to reach defined rank
```lua
exports.xperience:GetXPToRank(rank --[[ integer ]])
```

### Server Side

#### Exports
Get player's XP
```lua
exports.xperience:GetPlayerXP(playerId --[[ integer ]])
```

Get player's rank
```lua
exports.xperience:GetPlayerRank(playerId --[[ integer ]])
```

Get player's required XP to rank up
```lua
exports.xperience:GetPlayerXPToNextRank(playerId --[[ integer ]])
```

Get player's required XP to reach defined rank
```lua
exports.xperience:GetPlayerXPToRank(playerId --[[ integer ]], rank --[[ integer ]])
```

#### Events
```lua
TriggerClientEvent('xperience:client:addXP', playerId --[[ integer ]], xp --[[ integer ]])

TriggerClientEvent('xperience:client:removeXP', playerId --[[ integer ]], xp --[[ integer ]])

TriggerClientEvent('xperience:client:setXP', playerId --[[ integer ]], xp --[[ integer ]])

TriggerClientEvent('xperience:client:setRank', playerId --[[ integer ]], rank --[[ integer ]])
```

## Rank Events

Listen for rank up event
```lua
AddEventHandler("experience:client:rankUp", function(newRank, previousRank)
    -- do something when player ranks up
end)
```

Listen for rank down event
```lua
AddEventHandler("experience:client:rankDown", function(newRank, previousRank)
    -- do something when player ranks down
end)
```

## Rank Actions
You can define callbacks on each rank by using the `Action` function.

The function will be called both when the player reaches the rank and drops to the rank.

```lua
Config.Ranks = {
    [1] = { XP = 0 },
    [2] = {
        XP = 800, -- The XP required to reach this rank
        Action = function(rankUp, prevRank)
            -- rankUp: boolean      - whether the player reached or dropped to this rank
            -- prevRank: number     - the player's previous rank
        end
    },
    [3] = { XP = 2100 },
    [4] = { XP = 3800 },
    ...
}
```

## QBCore Integration

If `Config.UseQBCore` is set to `true` then the player's xp and rank are stored in their metadata. The metadata is saved whenever a player's xp / rank changes.

#### Client
```lua
local PlayerData = QBCore.Functions.GetPlayerData()
local xp = PlayerData.metadata.xp
local rank = PlayerData.metadata.rank
```

#### Server
```lua
local Player = QBCore.Functions.GetPlayer(src)
local xp = Player.PlayerData.metadata.xp
local rank = Player.PlayerData.metadata.rank
```

# FAQ
### How do I give XP to a player when they've done something?

Example of giving a player 100 XP for shooting another player
```lua
AddEventHandler('gameEventTriggered', function(event, data)
    if event == "CEventNetworkEntityDamage" then
        local victim      = tonumber(data[1])
        local attacker    = tonumber(data[2])
        local weaponHash  = tonumber(data[5])
        local meleeDamage = tonumber(data[10]) ~= 0 and true or false 

        -- Don't register melee damage
        if not meleeDamage then
            -- Check victim and attacker are both players
            if (IsEntityAPed(victim) and IsPedAPlayer(victim)) and (IsEntityAPed(attacker) and IsPedAPlayer(attacker)) then
                if attacker == PlayerPedId() then -- We are the attacker
                    exports.xperience:AddXP(100) -- Give player 100 xp for getting a hit
                end
            end
        end
    end
end)
```

### How do I do something when a player's rank changes?

You can either utilise [Rank Events](#rank-events) or [Rank Actions](#rank-actions).

Example of giving a minigun with `500` bullets to a player for reaching rank `10`:

#### Rank Event
```lua
AddEventHandler("experience:client:rankUp", function(newRank, previousRank)
    if newRank == 10 then
        local player = PlayerPedId()
        local weapon = `WEAPON_MINIGUN`
        
        if not HasPedGotWeapon(player, weapon, false) then
            -- Player doesn't have weapon so give it them loaded with 500 bullets
            GiveWeaponToPed(player, weapon, 500, false, false)
        else
            -- Player has the weapon so give them 500 bullets for it
            AddAmmoToPed(player, weapon, 500)
        end
    end
end)
```

#### Rank Action
```lua
Config.Ranks = {
    [1] = { XP = 0 },
    [2] = { XP = 800 },
    [3] = { XP = 2100 },
    [4] = { XP = 3800 },
    [5] = { XP = 6100 },
    [6] = { XP = 9500 },
    [7] = { XP = 12500 },
    [8] = { XP = 16000 },
    [9] = { XP = 19800 },
    [10] = {
        XP = 24000,
        Action = function(rankUp, prevRank)
            if rankUp then -- only run when player moved up to this rank
                local player = PlayerPedId()
                local weapon = `WEAPON_MINIGUN`
        
                if not HasPedGotWeapon(player, weapon, false) then
                    -- Player doesn't have weapon so give it them loaded with 500 bullets
                    GiveWeaponToPed(player, weapon, 500, false, false)
                else
                    -- Player has the weapon so give them 500 bullets for it
                    AddAmmoToPed(player, weapon, 500)
                end
            end
        end
    },
    [11] = { XP = 28500 },
    ...
}
```
