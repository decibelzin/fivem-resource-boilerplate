--- Jogador online (RAM). Criado pelo playerRegistry no primeiro uso; sai no forget.
OnlinePlayer = class()

function OnlinePlayer:__init(source, identifier, name)
    self.source = source
    self.identifier = identifier
    self.name = name
    self.joinedAt = os.time()
end

---@param permission string
---@return boolean
function OnlinePlayer:hasPermission(permission)
    return Framework.hasPermission(self.source, permission)
end
