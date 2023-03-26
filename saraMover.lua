local config = {
    --- You can add up unlimited commands here.
    commands = {
        { command = 'wtw', from = 'world1', to = 'world1a', item = 4585, background = 880 },
        { command = 'vtw', from = 'world2:doorid', to = 'world2a:doorid', item = 4585 },
        { command = 'wtv', from = 'world3:doorid', to = 'world3a:doorid', item = 4585 },
        { command = 'vtv', from = 'world4:doorid', to = 'world4a:doorid', item = 4585 },
    },

    --- Optional to use for only one door id for your worlds.
    id = 'doorid',

    --- Webhook URL to send the information of your bots activities.
    webhook = 'https://discord.com/api/webhooks/etc'
}

local saraMover = assert(load(request('GET', 'https://raw.githubusercontent.com/junssekut/saraMover/main/src/saraMover-src.lua'))())

saraMover.init(config)