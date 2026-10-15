--- Textos do jogador por CHAVE. Cada config preenche o seu bloco (`Messages.<modulo> = { ... }`) e server e
--- client resolvem a mesma chave — pela rede vai só a chave e os parâmetros, nunca o texto pronto
--- (a config shared já está no client).
---   Text('reports.sent', 12)              → 'Report #12 enviado — ...'
---   Text('reports.errors.cooldown')       → texto do código de erro
Messages = {}

---@param key string caminho com pontos dentro de `Messages`
---@return string|nil texto formatado; nil = chave inexistente
function Text(key, ...)
    local node = Messages
    for part in key:gmatch('[^%.]+') do
        node = type(node) == 'table' and node[part] or nil
    end

    if (type(node) ~= 'string') then
        return nil
    end

    -- O texto é editável pelo comprador: placeholder a mais não pode derrubar quem chama.
    local ok, text = pcall(string.format, node, ...)
    return ok and text or node
end
