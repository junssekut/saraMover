---@class config
local config = {
    commands = {
        { command = 'wtw', from = '', to = '', item = 4585, background = 880 },
        { command = 'vtw', from = '', to = '', item = 4585, background = 880 },
        { command = 'wtv', from = '', to = '', item = 4585 },
        { command = 'vtv', from = '', to = '', item = 4585 },
    },

    id = 'doorid',

    webhook = 'https://discord.com/api/webhooks/etc'
}

---@alias CommandOption
---| "'wtw'" # World to world
---| "'vtw'" # Vend to world
---| "'wtv'" # World to vend
---| "'vtv'" # Vend to vend

---@alias ScanOption
---| "'TAKE'" # Scan option for taking items
---| '"STORE"' # Scan option for storing items

---@alias ExecuteStatus
---| "'STARTING'" # Moving items
---| "'FINISHED'" # Moved items
---| "'ITEMS_EMPTY'" # Empty items execution
---| "'TAKING_ITEMS'" # Taking items
---| "'STORING_ITEMS'" # Storing items

---@class Command
---@field public command CommandOption
---@field public from string
---@field public to string
---@field public item number
---@field public background? number

---@class TileScanned
---@field public x number
---@field public y number
---@field public data number

---@class saraMover
local saraMover = { _VERSION = '1.0d', _AUTHOR = 'junssekut#4964', _CONTRIBUTORS = {} }

local saraCore = assert(load(request('GET', 'https://raw.githubusercontent.com/junssekut/saraCore/main/src/saraCore.lua'))())

---Localized Functions
local type = _G.type
local tinsert = _G.table.insert
local sformat = _G.string.format
local mfloor = _G.math.floor
local rawerror = _G.error

local error = function (message) rawerror(message, 0) end

local getTile = _G.getTile

local jencode = saraCore.Json.encode --[[@as function]]
local tcontains = saraCore.TableUtils.contains --[[@as function]]
local tassertv = saraCore.AssertUtils.tassertv --[[@as function]]
local warp = saraCore.WorldHandler.warp --[[@as function]]
local winside = saraCore.WorldHandler.isInside --[[@as function]]
local pcollect = saraCore.PacketHandler.collect --[[@as function]]
local check_connection = saraCore.Auth.c --[[@as function]]
local full = saraCore.TileHandler.full --[[@as function]]
local drop = saraCore.InventoryHandler.drop --[[@as function]]
local vend = saraCore.PacketHandler.vend --[[@as function]]
local tvend = saraCore.PacketHandler.tvend --[[@as function]]
local nformat = saraCore.NumberUtils.nformat --[[@as function]]
local getwdoor = saraCore.TileHandler.getWhiteDoor --[[@as function]]
local idatabase = saraCore.ItemDatabase --[[@as table]]
local isprites = saraCore.ItemSprites --[[@as table]]

---
---Validate a command and handle the throwing errors
---if it's not valid.
---
---@param key string
---@param value any
---@param expected_type type
local function validationCheck(key, value, expected_type)
    tassertv('validationcheck<key>', key, 'string')
    tassertv('validationcheck<expected_type>', expected_type, 'string')

    if type(value) == expected_type then return end

    error(sformat('Validation Error: Key `%s` must be a %s value.', key, expected_type))
end

---
---Validates a command and handle the process
---of checking if it's valid or not.
---
---@param command Command
local function validateCommand(command)
    tassertv('validatecommand<command>', command, 'table')

    if not tcontains({ 'wtw', 'vtw', 'wtv', 'vtv' }, command.command) then error(sformat('Validation Error: Unknown command `%s`, available commands: wtw, vtw, wtv, vtv.', command.command)) end

    local default_command = { command = '', from = '', to = '', item = 0, background = 0 }

    for k, v in pairs(command) do
        if not default_command[k] then error(sformat('Validation Error: Unknown key `%s`, mistype?', k)) end

        validationCheck(k, v, type(default_command[k]))
    end

    if command.command:sub(-1) == 'w' then
        if not command.background then command.background = 0 end

        validationCheck('background', command.background, type(default_command.background))
    end
end

---
---Scan dropped objects based on their choosable option.
---
---@param command Command
---@param scan_option ScanOption
---@return TileScanned[]
local function scan(command, scan_option)
    tassertv('scan<command>', command, 'table')

    ---@type TileScanned[]
    local tiles = {}

    if scan_option == 'TAKE' and command.command == 'wtw' then return tiles end

    if scan_option == 'STORE' and command.command:sub(-1) == 'w' then
        if command.background == 0 then
            local white_door = getwdoor()

            for x = 1, 98 do
                for y = white_door.y - 2, white_door.y do
                    if getTile(x, y).flags == 0 and getTile(x + 1, y).flags == 0 then
                        tinsert(tiles, { x = x, y = y })
                    end
                end
            end

            return tiles
        end

        for x = 0, 99 do
            for y = 0, 53 do
                local tile = getTile(x, y)

                if tile and (tile.fg == command.background or tile.bg == command.background) then
                    tinsert(tiles, { x = x, y = y }) --[[@as TileScanned]]
                end
            end
        end

        return tiles
    end

    if command.command:find('v') then
        for x = 0, 99 do
            for y = 0, 53 do
                local tile = getTile(x, y)

                if tile and tile.fg == 2978 then
                    tinsert(tiles, { x = x, y = y, data = tile.data } --[[@as TileScanned]])
                end
            end
        end

        return tiles
    end

    return tiles
end

---
---Take items dropped or inside vend.
---
---@param command Command
---@param fworld string
---@param fid string
---@param tiles? TileScanned[]
---@return boolean, number
local function take(command, fworld, fid, tiles)
    tassertv('take<command>', command, 'table')
    tassertv('take<fworld>', fworld, 'string')
    tassertv('take<fid>', fid, 'string')

    local take_count = 0
    local take_option = command.command:sub(0, 1)

    if take_option == 'w' then
        for _, object in pairs(getObjects()) do
            if findItem(object.id) == 200 then break end

            if object.id == command.item then
                local object_x, object_y = mfloor(object.x * ( 1 / 32 )), mfloor(object.y * ( 1 / 32 ))

                if not findPath(object_x, object_y) then
                    sleep(500)
                else
                    sleep(200)

                    check_connection(fworld, fid, object_x, object_y, true)

                    pcollect(object.oid, object.x, object.y)

                    sleep(200)

                    take_count = take_count + object.count

                    if findItem(object.id) == 200 then break end
                end
            end
        end

    end

    if take_option == 'v' then
        tassertv('take<tiles>', tiles, 'table')

        if #tiles == 0 then error('Take Error: Tiles empty') end

        for i = 1, #tiles do
            if findItem(command.item) == 200 then break end

            local tile = tiles[i] ---@diagnostic disable-line: need-check-nil

            if tile and tile.data == command.item then
                if not findPath(tile.x, tile.y) then
                    sleep(500)
                else
                    sleep(200)

                    check_connection(fworld, fid, tile.x, tile.y, true)

                    tvend(tile.x, tile.y)

                    if findItem(command.item) == 200 then break end
                end
            end

        end

        take_count = findItem(command.item)
    end

    return findItem(command.item) ~= 0, take_count
end

---
---
---
---@param command Command
---@param tworld string
---@param tid string
---@param tiles TileScanned[]
local function store(command, tworld, tid, tiles)
    tassertv('store<command>', command, 'table')
    tassertv('store<fworld>', tworld, 'string')
    tassertv('store<fid>', tid, 'string')
    tassertv('store<tiles>', tiles, 'table')

    if #tiles == 0 then error('Storing Error: Empty tiles') end

    local store_option = command.command:sub(-1)
    local store_count = findItem(command.item)

    for i = 1, #tiles do
        if findItem(command.item) == 0 then break end

        local tile = tiles[i]
        local x, y = tile.x, tile.y

        if store_option == 'w' then x = x + 1 end

        if (store_option == 'w' and (not full(x, y)) or true) then
            if not findPath(x, y) then
                sleep(500)
            else
                sleep(200)

                check_connection(tworld, tid, x, y, true)

                if store_option == 'w' then drop(command.item) end
                if store_option == 'v' then vend(command.item, x, y) end

                if findItem(command.item) == 0 then break end
            end
        end
    end

    return findItem(command.item) == 0, store_count
end

---
---Execute the command that has been configured.
---
---@param command Command
local function execute(command)
    tassertv('execute<command>', command, 'table')

    local caches = {
        ---@type TileScanned[]
        TAKE_TILES = {},
        ---@type TileScanned[]
        STORE_TILES = {},
        ITEMS_TOOK = 0,
        ITEMS_STORED = 0
    }

    local caches_meta

    do
        local protected_caches = {}
        caches_meta = {
            __index = function (table_value, key)
                return protected_caches[key]
            end,

            __newindex = function (table_value, key, value)
                ---TODO: update webhook here
                if key == 'STATUS' then
                    local bot = getBot()

                    webhook({ url = config.webhook, username = 'saraMover', content = sformat('[**%s**] %s: %s', bot.world, bot.name, value)})

                    sleep(250)
                end

                protected_caches[key] = value
            end
        }
    end

    setmetatable(caches, caches_meta)

    ---@type ExecuteStatus
    caches.STATUS = 'STARTING'

    local fworld, fid, tworld, tid = command.from, '', command.to, ''

    if fworld:find(':') then fworld, fid = fworld:match('(.+):(.+)') end
    if tworld:find(':') then tworld, tid = tworld:match('(.+):(.+)') end

    if config.id and config.id ~= '' then
        if fid == '' then fid = config.id end
        if tid == '' then tid = config.id end
    end

    while true do
        check_connection()

        --- Take
        if findItem(command.item) ~= 200 then
            if not winside(fworld) then
                while not warp(fworld, fid) do
                    sleep(5000)
                end

                sleep(2500)
            end

            if #caches.TAKE_TILES == 0 then caches.TAKE_TILES = scan(command, 'TAKE') end

            caches.STATUS = 'TAKING_ITEMS'

            local take_tries = 0
            local took, count

            while true do
                took, count = take(command, fworld, fid, caches.TAKE_TILES)

                if took or take_tries > 3 then break end

                take_tries = take_tries + 1

                sleep(1000)
            end

            if not took then caches.STATUS = 'ITEMS_EMPTY'; break end

            caches.ITEMS_TOOK = caches.ITEMS_TOOK + count
        end

        --- Store
        if findItem(command.item) > 0 then
            if not winside(tworld) then
                while not warp(tworld, tid) do
                    sleep(5000)
                end

                sleep(2500)
            end

            if #caches.STORE_TILES == 0 then caches.STORE_TILES = scan(command, 'STORE') end

            caches.STATUS = 'STORING_ITEMS'

            local _, count = store(command, tworld, tid, caches.STORE_TILES)

            caches.ITEMS_STORED = caches.ITEMS_STORED + count
        end

        sleep(1000)
    end

    caches.STATUS = 'FINISHED'

    webhook({
        url = config.webhook,
        username = 'saraMover',
        embed = jencode({
            title = sformat('%s -> %s', fworld, tworld),
            color = 4408131,
            fields = {
                { name = 'Item Name', value = sformat('%s %s', isprites[command.item] or isprites.BOX, idatabase[command.item]), inline = true },
                { name = 'Taken', value = sformat('%s x%s', (command.command:sub(0, 1) == 'w' and isprites.GLOBE or isprites[2978]), nformat(caches.ITEMS_TOOK)), inline = true },
                { name = 'Stored', value = sformat('%s x%s', (command.command:sub(-1) == 'w' and isprites.GLOBE or isprites[2978]), nformat(caches.ITEMS_STORED)), inline = true }
            },
            footer = saraCore.WebhookHandler.getDefaultFooter(),
            timestamp = saraCore.LuaDate(true):fmt('${iso}%z')
        })
    })

end

---
---Initialize and run the script.
---
---@param config_value config
function saraMover.init(config_value)
    tassertv('saraMover:init<config_value>', config_value, 'table')

    config = config_value

    for i = 1, #config.commands do
        local command = config.commands[i]

        validateCommand(command)

        execute(command)
    end
end

return saraMover