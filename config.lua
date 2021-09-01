Config = {}

Config.Locale       = 'en'

Config.Enabled      = true  -- enable / disable the resource
Config.Width        = 532   -- Sets the width of the XP bar in px
Config.Timeout      = 5000 -- Sets the interval in ms that the XP bar is shown before fading out
Config.BarSegments  = 10    -- Sets the number of segments the XP bar has. Native GTA:O is 10
Config.UIKey        = 20    -- The key that toggles the UI - default is "Z"

Config.Leaderboard = {
    Enabled     = true,    -- Enable / Disable the leaderboard
    ShowPing    = true,     -- Show player pings on the leaderboard
    Order       = "rank",   -- Order the player list by "name", "rank" or "id"
    PerPage     = 12        -- Max players to show per page
}