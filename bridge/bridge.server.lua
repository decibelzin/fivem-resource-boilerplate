--- OPEN FILE — connects the script to your server's framework.
--- Out of the box: standalone (license, FiveM name, ACE-only permissions). Replace the BODY of each
--- function with your framework's equivalent; do not rename functions or change their arguments.
--- Return plain values (string, number, boolean). An error here never breaks the script: it is
--- logged and the default value is used.
Bridge = {}

--- STABLE id of the CHARACTER — the key the script stores data under. If players can have several
--- characters per account, return the character id, not the account id. nil = character not loaded yet.
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
--- E.g. grant the permission to a group/rank from your framework.
---@param src number
---@param permission string
---@return boolean
function Bridge.hasPermission(src, permission)
    return false
end

--- Tell the script when the character is ready. Out of the box: on connect. With a character
--- selection screen, replace it with your framework's "character loaded" event.
AddEventHandler('playerJoining', function()
    Framework.playerLoaded(source)
end)

--- If your framework supports logout / character switch without disconnecting, tell the script too:
-- AddEventHandler('<character unloaded event>', function(src)
--     Framework.playerUnloaded(src)
-- end)
