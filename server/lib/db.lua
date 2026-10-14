--- Registo declarativo de schema. Cada módulo declara as suas tabelas no próprio
--- `<modulo>.schema.lua`; o bootstrap aplica tudo no arranque (idempotente).
---
---   Schema.table('boilerplate_reports', [[CREATE TABLE IF NOT EXISTS boilerplate_reports (...)]])
---   Schema.column('boilerplate_reports', 'priority', [[ALTER TABLE boilerplate_reports ADD COLUMN ...]])
---   Schema.seed('reports-defaults', function() ... end)  -- corre após as tabelas, idempotente
---
--- Resource sem persistência: nenhum Schema.* registado → o bootstrap não toca no MySQL.
Schema = {
    tables = {},
    columns = {},
    seeds = {},
}

function Schema.table(name, ddl)
    table.insert(Schema.tables, { name = name, ddl = ddl })
end

function Schema.column(tableName, columnName, ddl)
    table.insert(Schema.columns, { table = tableName, column = columnName, ddl = ddl })
end

function Schema.seed(name, fn)
    table.insert(Schema.seeds, { name = name, fn = fn })
end

DatabaseBootstrap = class()

function DatabaseBootstrap:__init()
    self.log = Log.scope('db')
end

function DatabaseBootstrap:columnExists(tableName, columnName)
    local row = MySQL.single.await([[
        SELECT COUNT(*) AS total
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?
    ]], { tableName, columnName })

    return row and tonumber(row.total) > 0
end

---@return boolean ok, string code
function DatabaseBootstrap:run()
    for _, entry in ipairs(Schema.tables) do
        local ok, err = pcall(MySQL.query.await, entry.ddl)
        if (not ok) then
            self.log:error('table %s falhou: %s', entry.name, err)
            return false, 'schema_table_failed'
        end
    end

    for _, entry in ipairs(Schema.columns) do
        if (not self:columnExists(entry.table, entry.column)) then
            local ok, err = pcall(MySQL.query.await, entry.ddl)
            if (not ok) then
                self.log:error('column %s.%s falhou: %s', entry.table, entry.column, err)
                return false, 'schema_column_failed'
            end
        end
    end

    for _, entry in ipairs(Schema.seeds) do
        local ok, err = pcall(entry.fn)
        if (not ok) then
            self.log:error('seed %s falhou: %s', entry.name, err)
            return false, 'schema_seed_failed'
        end
    end

    return true, 'ok'
end

databaseBootstrap = DatabaseBootstrap()
