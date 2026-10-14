--- Entidade Report. Campos camelCase; a linha da DB (snake_case) entra só via :applyRow.
Report = class()

function Report:__init()
    self.id = nil
    self.authorIdentifier = nil
    self.authorName = nil
    self.message = nil
    self.status = REPORT_STATUS.OPEN
    self.closedBy = nil
    self.closedAt = nil
    self.createdAt = nil
end

function Report:applyRow(row)
    self.id = tonumber(row.id)
    self.authorIdentifier = row.author_identifier
    self.authorName = row.author_name
    self.message = row.message
    self.status = row.status
    self.closedBy = row.closed_by
    self.closedAt = Util.datetimeToUnix(row.closed_at)
    self.createdAt = Util.datetimeToUnix(row.created_at)
end

function Report:isOpen()
    return self.status == REPORT_STATUS.OPEN
end

function Report:markClosed(actor)
    self.status = REPORT_STATUS.CLOSED
    self.closedBy = actor
    self.closedAt = os.time()
end

--- Payload seguro para client/exports — sem o identifier do autor.
function Report:toPayload()
    return {
        id = self.id,
        authorName = self.authorName,
        message = self.message,
        status = self.status,
        createdAt = self.createdAt,
        closedAt = self.closedAt,
    }
end
