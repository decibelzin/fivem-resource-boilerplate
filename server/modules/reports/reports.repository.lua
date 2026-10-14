ReportsRepository = class()

local COLUMNS = 'id, author_identifier, author_name, message, status, closed_by, closed_at, created_at'

local function hydrate(row)
    if (not row) then
        return nil
    end

    local report = Report()
    report:applyRow(row)
    return report
end

---@return table|nil Report
function ReportsRepository:findById(id)
    return hydrate(MySQL.single.await(
        ('SELECT %s FROM boilerplate_reports WHERE id = ? LIMIT 1'):format(COLUMNS),
        { id }
    ))
end

--- Insere e devolve a entidade já hidratada (created_at vem da DB).
---@return table|nil Report
function ReportsRepository:create(authorIdentifier, authorName, message)
    local id = MySQL.insert.await([[
        INSERT INTO boilerplate_reports (author_identifier, author_name, message, status)
        VALUES (?, ?, ?, ?)
    ]], { authorIdentifier, authorName, message, REPORT_STATUS.OPEN })

    if (not id) then
        return nil
    end

    return self:findById(id)
end

function ReportsRepository:countOpenByAuthor(authorIdentifier)
    local total = MySQL.scalar.await([[
        SELECT COUNT(*) FROM boilerplate_reports
        WHERE author_identifier = ? AND status = ?
    ]], { authorIdentifier, REPORT_STATUS.OPEN })

    return tonumber(total) or 0
end

--- Fila de atendimento: mais antigos primeiro.
---@return table[] Report[]
function ReportsRepository:listOpen(limit)
    local rows = MySQL.query.await(
        ('SELECT %s FROM boilerplate_reports WHERE status = ? ORDER BY created_at, id LIMIT ?'):format(COLUMNS),
        { REPORT_STATUS.OPEN, limit }
    ) or {}

    local reports = {}
    for i, row in ipairs(rows) do
        reports[i] = hydrate(row)
    end
    return reports
end

--- Fecha só se ainda estiver aberto — o WHERE status resolve a corrida entre dois staff.
---@return boolean closed
function ReportsRepository:close(id, closedBy)
    local affected = MySQL.update.await([[
        UPDATE boilerplate_reports SET status = ?, closed_by = ?, closed_at = CURRENT_TIMESTAMP
        WHERE id = ? AND status = ?
    ]], { REPORT_STATUS.CLOSED, closedBy, id, REPORT_STATUS.OPEN })

    return affected ~= nil and affected > 0
end

reportsRepository = ReportsRepository()
