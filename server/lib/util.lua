Util = {}

local log = Log.scope('util')

--- json.encode tolerante: string passa direto, nil continua nil.
function Util.encodeJson(value)
    if (value == nil) then
        return nil
    end
    if (type(value) == 'string') then
        return value
    end
    return json.encode(value)
end

--- json.decode tolerante: tabela passa direto (oxmysql pode já devolver decodificado), string
--- decodifica (pcall), nil/inválido → nil.
function Util.decodeJson(value)
    if (value == nil or value == '') then
        return nil
    end
    if (type(value) == 'table') then
        return value
    end
    if (type(value) ~= 'string') then
        return nil
    end
    local ok, decoded = pcall(json.decode, value)
    if (ok) then
        return decoded
    end
    return nil
end

--- DB datetime → unix seconds. Aceita os formatos que o oxmysql pode devolver: número em
--- MILISSEGUNDOS (padrão do oxmysql para DATE/DATETIME/TIMESTAMP), string 'YYYY-MM-DD HH:MM:SS'
--- e ISO 'YYYY-MM-DDTHH:MM:SS'. nil/0/inválido → nil.
function Util.datetimeToUnix(value)
    if (value == nil) then
        return nil
    end

    if (type(value) == 'number') then
        if (value <= 0) then
            return nil
        end
        -- segundos (~1.7e9 hoje) << 1e11 << ms (~1.7e12). Normaliza ms → segundos.
        if (value >= 100000000000) then
            return math.floor(value / 1000)
        end
        return math.floor(value)
    end

    if (type(value) ~= 'string') then
        return nil
    end

    local year, month, day, hour, min, sec = value:match('(%d+)-(%d+)-(%d+)[ T](%d+):(%d+):(%d+)')
    if (not year) then
        return nil
    end

    return os.time({
        year = tonumber(year), month = tonumber(month), day = tonumber(day),
        hour = tonumber(hour), min = tonumber(min), sec = tonumber(sec),
    })
end

--- unix seconds → 'YYYY-MM-DD HH:MM:SS'. nil passa nil.
function Util.unixToDatetime(unix)
    if (not unix) then
        return nil
    end
    return os.date('%Y-%m-%d %H:%M:%S', unix)
end

--- Tira espaços das pontas. Não-string → '' (input do client chega com qualquer tipo).
function Util.trim(value)
    if (type(value) ~= 'string') then
        return ''
    end
    return value:match('^%s*(.-)%s*$')
end

--- Roda `fn` em thread separada; loga falha sem derrubar o caller (escritas não críticas).
---@param label string contexto para o log de erro
function Util.background(label, fn)
    CreateThread(function()
        local ok, err = pcall(fn)
        if (not ok) then
            log:error('background %s falhou: %s', label, err)
        end
    end)
end
