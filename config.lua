Config = {}

Config.Debug        = true     -- Prints debug info to the console

Config.Timeout      = 5000      -- Sets the time in ms that the XP bar is displayed before fading out
Config.UIKey        = 'z'       -- The key that toggles the UI - default is "z"
Config.Theme        = 'native'  -- Set the default theme

Config.Themes = {
    native = {
        segments = 10,  -- Sets the number of segments the XP bar has. Native = 10, Max = 20
        width = 532     -- Sets the width of the XP bar in px
    },

    hitman = {
        segments = 80,
        width = 800
    },
    
    hexagon = {
        segments = 16,
        width = 400
    },
}

Config.UseQBCore    = false
Config.UseESX       = false

Config.ESXIdentifierColumn = 'identifier'
