local config = {
    --- You can add up unlimited commands here.
    commands = {
        { command = 'wtw', from = 'world1', to = 'world1a', id = 4585, background = 880 },
        { command = 'vtw', from = 'world2:doorid', to = 'world2a:doorid', id = 4585, background = 880 },
        { command = 'wtv', from = 'world3:doorid', to = 'world3a:doorid', id = 4585 },
        { command = 'vtv', from = 'world4:doorid', to = 'world4a:doorid', id = 4585 },
    },

    --- Webhook URL to send the information of your bots activities.
    webhook = 'https://discord.com/api/webhooks/etc'
}

local saraMover = assert(load(request('GET', 'https://raw.githubusercontent.com/junssekut/saraMover/main/src/saraMover-src.lua'))())

saraMover.init(config)