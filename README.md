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

## Table of Contents
* [Install](#install)
* [Transitioning from esx_xp](#transitioning-from-esx_xp)
* [Usage](#usage)
* [Client Side](#client-side)
  - [Client Exports](#client-exports)
  - [Client Events](#client-events)
* [Server Side](#server-side)
  - [Server Exports](#server-exports)
  - [Server Triggers](#server-triggers)
  - [Server Events](#server-events)
* [Rank Actions](#rank-actions)
* [QBCore Integration](#qbcore-integration)
  - [Client](#client)
  - [Server](#server)
* [Admin Commands](#admin-commands)
* [FAQ](#faq)
* [License](#license)


## Install

Select an option:
* Option 1 - If you want to use `xperience` as a standalone resource then import `xperience_standalone.sql` only
* Option 2 - If using `ESX` with `Config.UseESX` set to `true` then import `xperience_esx.sql` only. This adds the `xp` and `rank` columns to the `users` table
    - If you're transitioning from `esx_xp`, then don't import `xperience_esx.sql`, instead see [Transitioning from esx_xp](#transitioning-from-esx_xp)
* Option 3 - If using `QBCore` with `Config.UseQBCore` set to `true` then there's no need to import any `sql` files as the xp and rank are saved to the player's metadata - see [QBCore Integration](#qbcore-integration)

then:

* Drop the `xperience` directory into you `resources` directory
* Add `ensure xperience` to your `server.cfg` file

By default this resource uses `oxmysql`, but if you don't want to use / install it then you can use `mysql-async` by following these instructions:

* Uncomment the `'@mysql-async/lib/MySQL.lua',` line in `fxmanifest.lua` and comment out the `'@oxmysql/lib/MySQL.lua'` line

## Transitioning from esx_xp
If you previously used `esx_xp` and are still using `es_extended` then do the following to make your current stored xp / rank data compatible with `xperience` 
* Rename the `rp_xp` column in the `users` table to `xp`
* Rename the `rp_rank` column in the `users` table to `rank`
* Set `Config.UseESX` to `true`

## Usage

### Client Side

#### Client Exports
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

#### Client Events

Listen for rank up event on the client
```lua
AddEventHandler("xperience:client:rankUp", function(newRank, previousRank, player)
    -- do something when player ranks up
end)
```

Listen for rank down event on the client
```lua
AddEventHandler("xperience:client:rankDown", function(newRank, previousRank, player)
    -- do something when player ranks down
end)
```

### Server Side

#### Server Exports
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

#### Server Triggers
```lua
TriggerClientEvent('xperience:client:addXP', playerId --[[ integer ]], xp --[[ integer ]])

TriggerClientEvent('xperience:client:removeXP', playerId --[[ integer ]], xp --[[ integer ]])

TriggerClientEvent('xperience:client:setXP', playerId --[[ integer ]], xp --[[ integer ]])

TriggerClientEvent('xperience:client:setRank', playerId --[[ integer ]], rank --[[ integer ]])
```

#### Server Events
```lua
RegisterNetEvent('xperience:server:rankUp', function(newRank, previousRank)
    -- do something when player ranks up
end)

RegisterNetEvent('xperience:server:rankDown', function(newRank, previousRank)
    -- do something when player ranks down
end)
```

## Rank Actions
You can define callbacks on each rank by using the `Action` function.

The function will be called both when the player reaches the rank and drops to the rank.

You can check whether the player reached or dropped to the new rank by utilising the `rankUp` parameter.

```lua
Config.Ranks = {
    [1] = { XP = 0 },
    [2] = {
        XP = 800, -- The XP required to reach this rank
        Action = function(rankUp, prevRank, player)
            -- rankUp: boolean      - whether the player reached or dropped to this rank
            -- prevRank: number     - the player's previous rank
            -- player: integer      - The current player            
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

# Admin Commands

These require ace permissions: e.g. `add_ace group.admin command.addXP allow`

```lua
-- Award XP to player
/addXP [playerId] [xp]

-- Deduct XP from player
/removeXP [playerId] [xp]

-- Set a player's XP
/setXP [playerId] [xp]

-- Set a player's rank
/setRank [playerId] [rank]
```

# FAQ

### How do I award players XP for X amount of playtime?

Example of awarding players 100XP for every 30mins of playtime
```lua
-- Server side
CreateThread(function()
    local interval = 30   -- interval in minutes
    local xp = 100        -- XP amount to award every interval

    while true do
        for i, src in pairs(GetPlayers()) do
            TriggerClientEvent('xperience:client:addXP', src, xp)
        end
        
        Wait(interval * 60 * 1000)
    end
end)
```

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

You can either utilise [Rank Events](#client-events) or [Rank Actions](#rank-actions).

Example of giving a minigun with `500` bullets to a player for reaching rank `10`:

#### Rank Event
```lua
AddEventHandler("xperience:client:rankUp", function(newRank, previousRank, player)
    if newRank == 10 then
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
        Action = function(rankUp, prevRank, player)
            if rankUp then -- only run when player moved up to this rank
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


# License

```
xperience - XP Ranking System for FiveM

Copyright (C) 2021 Karl Saunders

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>
```
