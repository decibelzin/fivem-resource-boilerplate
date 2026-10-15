--- OPEN FILE — connects the script to your server's framework.
--- Out of the box: standalone (license, FiveM name, ACE-only permissions). Replace the BODY of each
--- function with your framework's equivalent; do not rename functions or change their arguments.
--- Return plain values (string, number, boolean). An error here never breaks the script: it is
--- logged and the default value is used.
Bridge = {}

--- STABLE id of the CHARACTER — the key the script stores data under. If players can have several
--- characters per account, return the character id, not the account id. nil = character not loaded yet.
--- Called once per player, the first time the script needs them; the result is cached.
---@param src number
---@return string|number|nil
function Bridge.identifier(src)
    return GetPlayerIdentifierByType(src, 'license')
end

--- Name shown by the script (e.g. the character name). nil = FiveM name.
---@param src number
---@return string|nil
function Bridge.displayName(src)
    return GetPlayerName(src)
end

--- EXTRA permission on top of ACE, which always applies (`add_ace group.admin <permission> allow`).
--- E.g. grant the permission to a group/rank from your framework. Called often (e.g. for every online
--- player when the script alerts staff): keep it cheap.
---@param src number
---@param permission string
---@return boolean
function Bridge.hasPermission(src, permission)
    return false
end

--- If players pick a character after connecting, or can switch / log out without disconnecting, tell
--- the script every time the character changes, so it stops using the previous one:
-- AddEventHandler('<character loaded event>', function(src)
--     Framework.characterChanged(src)
-- end)
-- AddEventHandler('<character unloaded event>', function(src)
--     Framework.characterChanged(src)
-- end)
