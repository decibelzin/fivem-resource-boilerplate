# Playbook — criar um módulo novo

Receita completa. Exemplo guia: módulo `reports` — copie o formato dele, ficheiro a ficheiro.
Crie só as camadas que o módulo precisa (simplicidade primeiro).

## Passos

1. **Config** — `shared/config/<modulo>.lua` com `<Modulo>Config = { ... }` (limites, cooldowns, ACE,
   nomes de comando, textos do jogador por `code`) e os enums partilhados. Nada no manifest (glob).

2. **Eventos** — se o módulo empurra algo para o client, acrescente em `shared/constants.lua`:
   ```lua
   MEU_EVENTO = ('%s:<modulo>:<acao>'):format(RESOURCE),
   ```

3. **Schema** (`server/modules/<modulo>/<modulo>.schema.lua`) — se persiste dados:
   ```lua
   Schema.table('<resource>_<tabela>', [[
   CREATE TABLE IF NOT EXISTS <resource>_<tabela> (
       id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
       owner_identifier VARCHAR(64) NOT NULL,
       ...
       created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
       PRIMARY KEY (id),
       KEY idx_<resource>_<tabela>_owner (owner_identifier)
   ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
   ]])
   -- coluna nova em tabela existente (idempotente):
   -- Schema.column('<resource>_<tabela>', 'nova', 'ALTER TABLE <resource>_<tabela> ADD COLUMN ...')
   -- dados base (idempotente — INSERT IGNORE):
   -- Schema.seed('<modulo>-defaults', function() ... end)
   ```

4. **Entity** (`<modulo>.entity.lua`) — `class()` com campos camelCase, `:applyRow(row)` e `:toPayload()`
   (o que pode sair para client/exports — nunca identifiers alheios).

5. **Repository** (`<modulo>.repository.lua`) — todo o SQL; hidrata entidades com um `local function hydrate`.

6. **Service** (`<modulo>.service.lua`) — regras. Métodos retornam `ok, code, data?`. Recebe
   `OnlinePlayer` (não `source`) quando a ação é de um jogador. Estado anti-spam/lock marcado antes do
   primeiro await. Eventos para client sempre unicast.

7. **Adapters** (opcionais, finos):
   - `<modulo>.commands.lua` — `CreateCommand(Config.commands.x, handler, { console = true, permission = Config.permission })`.
   - `<modulo>.events.lua` — `RegisterNetEvent` cru (cheque `App.ready` e valide o payload).

8. **API pública**:
   - Outros resources (server) → `server/api/exports.lua`.
   - Client → `server/api/rpc.lua` com `withPlayer(function(player, args) ... end)` (ou `guard`).

9. **Client** (`client/modules/<modulo>/`):
   - `<modulo>.api.lua` — `class()` com um método por RPC (`RPC.await`).
   - `<modulo>.commands.lua` — `RegisterCommand` + `CreateThread` + feedback por `code` via `Notify`.
   - `<modulo>.events.lua` — `RegisterNetEvent(EVENT.X, ...)` validando `type(payload) == 'table'`.

10. **Docs** — `docs/api.md` (exports, RPC, eventos, comandos, tipos). Decisão de arquitetura →
    `docs/decisions.md`.

## Integração com a framework

Dinheiro já está no contrato — use no service, com o valor calculado no server:

```lua
local ok, code = Framework.removeMoney(player.source, MONEY_ACCOUNT.BANK, MeuConfig.price, 'meu_modulo:compra')
if (not ok) then
    return false, code -- insufficient · not_loaded · invalid_amount · not_supported (standalone) · failed
end
```

Precisa de algo que não está (item, job…)? Acrescente no contrato **e** nos 5 adapters:

```lua
-- server/lib/framework.bridge.lua — valida a entrada e delega
---@return boolean ok, string code, string|nil job
function Framework.getJob(src)
    return adapter.getJob(src)
end

-- server/bridge/qbox.lua (dentro da factory)
function adapter.getJob(src)
    local player = exports.qbx_core:GetPlayer(src)
    if (not player) then
        return false, 'not_loaded'
    end
    return true, 'ok', player.PlayerData.job.name
end

-- server/bridge/standalone.lua
function adapter.getJob()
    return false, 'not_supported'
end
```

Não tem certeza da assinatura numa framework? Comentário `[confirmar]` no adapter — nunca invente.

## Armadilhas conhecidas

- Load order é **alfabético** dentro de cada glob: nunca use instância de outro módulo no top-level.
- `CreateCommand`, `RPC.register` e `Schema.*` no top-level são OK (libs carregam antes).
- `RPC.await` yielda: só dentro de `CreateThread`/NUI callback.
- `#str` conta bytes — use `utf8.len(str)` para limites de texto.
- oxmysql devolve DATETIME em ms → `Util.datetimeToUnix`.
- Dado de jogador carrega em `Framework.onPlayerLoaded`, não no `playerJoining` (multichar: o
  personagem só existe depois da seleção). Chave = `player.identifier`, que é por personagem.
- Sem persistência? Não crie `*.schema.lua` e remova `@oxmysql/lib/MySQL.lua` do fxmanifest.
