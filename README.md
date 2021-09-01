# xperience
XP Ranking System for FiveM

- [Install](#install)
- [Usage](#usage)
  * [Client](#client)
  * [Server](#server)
- [Rank Events](#rank-events)
- [Rank Actions](#rank-actions)

## Requirements
* [`ghmattimysql`](https://github.com/GHMatti/ghmattimysql) or [`mysql-async`](https://github.com/brouznouf/fivem-mysql-async)
 
## Install
* Drop the `xperience` directory into you `resources` directory
* Add `ensure xperience` to your `server.cfg` file

By default this resource uses `ghmattimysql`, but if you don't want to use / install it then you can use `mysql-async` by following these instructions:

* In `config.lua` change `Config.MySQLLib = 'ghmattimysql'` to `Config.MySQLLib = 'mysql-async'`
* Uncomment the `'@mysql-async/lib/MySQL.lua'` line in `fxmanifest.lua`

The required database table will be installed automatically for you.

## Usage

### Client
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

### Server
```lua
TriggerClientEvent('xperience:client:addXP', source --[[ integer ]], xp --[[ integer ]])

TriggerClientEvent('xperience:client:removeXP', source --[[ integer ]], xp --[[ integer ]])

TriggerClientEvent('xperience:client:setXP', source --[[ integer ]], xp --[[ integer ]])

TriggerClientEvent('xperience:client:setRank', source --[[ integer ]], rank --[[ integer ]])
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
    { XP = 0 },
    {
        XP = 800, -- The XP required to reach this rank
        Action = function(rankUp, prevRank)
            -- rankUp: boolean      - whether the player reached or dropped to this rank
            -- prevRank: number     - the player's previous rank
        end
    },
    { XP = 2100 },
    { XP = 3800 },
    ...
}
```