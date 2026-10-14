--- Logger com escopo. Uso:
---   local log = Log.scope('reports')
---   log:info('report criado id=%s autor=%s', id, identifier)
---   log:error('insert falhou: %s', err)
--- Nível via convar `<resource>_log_level` (debug|info|warn|error). Default: info.
Log = {}

local LEVELS = { debug = 1, info = 2, warn = 3, error = 4 }
local resourceName = GetCurrentResourceName()
local levelConvar = ('%s_log_level'):format(resourceName)

local function currentLevel()
    return LEVELS[GetConvar(levelConvar, 'info')] or LEVELS.info
end

local Scoped = class()

function Scoped:__init(scope)
    self.prefix = ('[%s:%s]'):format(resourceName, scope)
end

function Scoped:write(level, fmt, ...)
    if (LEVELS[level] < currentLevel()) then
        return
    end

    local ok, message = pcall(string.format, fmt, ...)
    if (not ok) then
        message = tostring(fmt)
    end

    print(('%s %s'):format(self.prefix, message))
end

function Scoped:debug(fmt, ...) self:write('debug', fmt, ...) end
function Scoped:info(fmt, ...) self:write('info', fmt, ...) end
function Scoped:warn(fmt, ...) self:write('warn', fmt, ...) end
function Scoped:error(fmt, ...) self:write('error', fmt, ...) end

---@param scope string
---@return table logger com :debug/:info/:warn/:error
function Log.scope(scope)
    return Scoped(scope)
end
