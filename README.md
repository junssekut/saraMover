### saraMover

Move your desired items with automation!

---

![saraMover](img/saraMover.png?raw=true, 'saraMover')

If you need help implementing this, feels free to dm me at discord junssekut#4964 or join my [discord server](https://dsc.gg/machseeman).

## Output
> The output of the script would be:

Will be updated later.

## How To Use

> Creating your custom config:
```lua
local config = {
    --- You can add up unlimited commands here.
    commands = {
        { command = 'wtw', from = 'world1', to = 'world1a', id = 4585, background = 880 },
        { command = 'vtw', from = 'world2:doorid', to = 'world2a:doorid', id = 4585, background = 880 },
        { command = 'wtv', from = 'world3:doorid', to = 'world3a:doorid', id = 4585 },
        { command = 'vtv', from = 'world4:doorid', to = 'world4a:doorid', id = 4585 },
    },

    --- Webhook URL to send the information of your bots activities.
    webhook = ''
}
```

> Add this code inside your script (online fetch):
```lua
--- Fetch the online script and load it.
local saraMover = assert(load(request('GET', 'https://raw.githubusercontent.com/junssekut/saraMover/main/src/saraMover-src.lua'))())

--- Initialize with your custom config!
saraMover.init(config)
```

> Add this code inside your script if you want it offline or locally ( not recommended, since you won't get any updates or fixes ):
```lua
--- 'saraMover.lua' must be the same folder as Pandora.
local saraMover = require('saraMover')

--- Initialize with your custom config!
saraMover.init(config)
```
