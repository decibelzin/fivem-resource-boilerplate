# Playbook — criar um módulo novo

Receita completa. O template não traz módulo de feature: o exemplo `reports` no fim deste ficheiro
(jogador reporta → staff é avisada → staff fecha → autor é avisado) mostra cada camada funcionando.
Copie o formato, ficheiro a ficheiro, e crie só as camadas que o módulo precisa.

## Passos

1. **Config** — `shared/config/<modulo>.lua` com `<Modulo>Config = { ... }` (limites, cooldowns, ACE,
   nomes de comando, textos do jogador por `code`) e os enums partilhados. Nada no manifest (glob).
   Ficheiro aberto ao comprador: comentários **em inglês**.

2. **Eventos** — se o módulo empurra algo para o client, acrescente em `shared/constants.lua`:
   `MEU_EVENTO = ('%s:<modulo>:<acao>'):format(RESOURCE),`

3. **Schema** (`server/modules/<modulo>/<modulo>.schema.lua`) — se persiste dados. Tabela prefixada pelo
   resource, `CREATE TABLE IF NOT EXISTS`. Coluna nova em tabela existente = `Schema.column(...)`;
   dados base = `Schema.seed(...)` com `INSERT IGNORE`.

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

## Feature que precisa da framework (dinheiro, item, job…)

O núcleo não conhece framework: a feature entra como função nova na ponte, só no script que a usa.

1. **`bridge/bridge.server.lua`** (aberto) — `Bridge.x` com default que funciona em standalone e devolve
   valor simples. O comentário é a doc do comprador (em inglês): diga o que devolver.
   ```lua
   --- Player balance in the account ('cash' | 'bank'). nil = server has no economy.
   ---@return number|nil
   function Bridge.getMoney(src, account)
       return nil
   end

   --- Remove `amount` from the account. true = removed.
   ---@return boolean
   function Bridge.removeMoney(src, account, amount)
       return false
   end
   ```

2. **`server/lib/framework.lua`** (núcleo) — `Framework.x` valida a entrada, chama com `call` (protegido)
   e converte para `ok, code`. As regras ficam aqui, não no ficheiro do comprador.
   ```lua
   ---@return boolean ok, string code
   function Framework.removeMoney(src, account, amount)
       amount = math.tointeger(amount) -- rejeita fração, NaN e inf
       if (not amount or amount < 1) then
           return false, 'invalid_amount'
       end

       local ok, balance = call('getMoney', src, account)
       if (not ok or type(balance) ~= 'number') then
           return false, 'not_supported'
       end
       if (balance < amount) then
           return false, 'insufficient'
       end

       local removed
       ok, removed = call('removeMoney', src, account, amount)
       if (not ok or removed ~= true) then
           return false, 'failed'
       end
       return true, 'ok'
   end
   ```

3. **`docs/api.md`** (seção Ponte) e changelog da versão. Contrato publicado não muda de nome, argumento
   nem retorno — o ficheiro do comprador quebraria no update.

## Armadilhas conhecidas

- Load order é **alfabético** dentro de cada glob: nunca use instância de outro módulo no top-level.
- `CreateCommand`, `RPC.register` e `Schema.*` no top-level são OK (libs carregam antes).
- `RPC.await` yielda: só dentro de `CreateThread`/NUI callback.
- `#str` conta bytes — use `utf8.len(str)` para limites de texto.
- oxmysql devolve DATETIME em ms → `Util.datetimeToUnix`.
- Dado de jogador carrega em `Framework.onPlayerLoaded`, não no `playerJoining` (com seleção de
  personagem, ele ainda não existe). Chave = `player.identifier`, que é por personagem.
- Sem persistência? Não crie `*.schema.lua` e remova `@oxmysql/lib/MySQL.lua` do fxmanifest.

## Exemplo completo — `reports`

Documente também em `docs/api.md`: RPC `reports.create`, eventos `REPORT_CREATED`/`REPORT_CLOSED`,
comandos `/report` e `/closereport`, tipo `ReportPayload`. No `server.cfg`:
`add_ace group.admin reports.manage allow`.

### `shared/config/reports.lua`

```lua
--- Player reports to staff. Everything a server owner may want to tweak lives here.
ReportsConfig = {
    --- ACE that allows closing reports and receiving new-report alerts.
    permission = 'reports.manage',

    commands = {
        create = 'report', -- player: /report <message>
        close = 'closereport', -- staff/console: /closereport <id>
    },

    minLength = 10,
    maxLength = 300,
    --- Minimum seconds between reports from the same player (in memory — resets on resource restart).
    cooldownSeconds = 120,
    maxOpenPerAuthor = 3,

    --- Text shown to the player. Errors are keyed by the `code` returned by the server.
    messages = {
        sent = 'Report #%s enviado — a staff foi avisada.',
        closed = 'Seu report #%s foi fechado pela staff.',
        staffNew = 'Report #%s de %s: %s',
        fallbackError = 'Não foi possível enviar o report (%s).',
        errors = {
            message_too_short = 'Descreva melhor o problema.',
            message_too_long = 'Mensagem longa demais.',
            cooldown = 'Aguarde um pouco antes de enviar outro report.',
            too_many_open = 'Você já tem reports abertos demais.',
            not_online = 'Você ainda não foi carregado no servidor.',
            not_ready = 'O servidor ainda está iniciando.',
            rpc_timeout = 'O servidor não respondeu. Tente de novo.',
        },
    },
}

REPORT_STATUS = {
    OPEN = 'open',
    CLOSED = 'closed',
}
```

### `shared/constants.lua` (dentro de `EVENT`)

```lua
    --- server → client (unicast, só staff): report novo. Payload = ReportPayload.
    REPORT_CREATED = ('%s:reports:created'):format(RESOURCE),

    --- server → client (unicast, só o autor): report fechado. Payload = ReportPayload.
    REPORT_CLOSED = ('%s:reports:closed'):format(RESOURCE),
```

### `server/modules/reports/reports.schema.lua`

```lua
--- Tabela prefixada com o nome do resource (o DB é partilhado); autor = identifier do personagem.
Schema.table('boilerplate_reports', [[
CREATE TABLE IF NOT EXISTS boilerplate_reports (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    author_identifier VARCHAR(64) NOT NULL,
    author_name VARCHAR(128) NOT NULL,
    message VARCHAR(512) NOT NULL,
    status VARCHAR(16) NOT NULL DEFAULT 'open',
    closed_by VARCHAR(128) NULL,
    closed_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_boilerplate_reports_author (author_identifier, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
]])
```

### `server/modules/reports/reports.entity.lua`

```lua
--- Entidade Report. Campos camelCase; a linha da DB (snake_case) entra só via :applyRow.
Report = class()

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
```

### `server/modules/reports/reports.repository.lua`

```lua
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
        SELECT COUNT(*) FROM boilerplate_reports WHERE author_identifier = ? AND status = ?
    ]], { authorIdentifier, REPORT_STATUS.OPEN })

    return tonumber(total) or 0
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
```

### `server/modules/reports/reports.service.lua`

```lua
--- Reports de jogador → staff. Fluxo: validar → persistir → avisar a audiência (unicast).
ReportsService = class()

function ReportsService:__init()
    self.log = Log.scope('reports')
    --- identifier → unix do último report (anti-spam; zera no restart do resource).
    self.lastCreatedAt = {}
end

--- Unicast para cada staff online — broadcast -1 é proibido (vaza dado e pesa na rede).
function ReportsService:notifyStaff(payload)
    playerRegistry:each(function(player)
        if (player:hasPermission(ReportsConfig.permission)) then
            TriggerClientEvent(EVENT.REPORT_CREATED, player.source, payload)
        end
    end)
end

---@param player table OnlinePlayer
---@param message any texto vindo do client — não confiável
---@return boolean ok, string code, table|nil data ReportPayload | { retryIn }
function ReportsService:create(player, message)
    message = Util.trim(message)

    local length = utf8.len(message) or #message
    if (length < ReportsConfig.minLength) then
        return false, 'message_too_short'
    end
    if (length > ReportsConfig.maxLength) then
        return false, 'message_too_long'
    end

    local now = os.time()
    local lastAt = self.lastCreatedAt[player.identifier]
    if (lastAt and now - lastAt < ReportsConfig.cooldownSeconds) then
        return false, 'cooldown', { retryIn = ReportsConfig.cooldownSeconds - (now - lastAt) }
    end

    -- Marca ANTES do primeiro await: o MySQL cede a vez e dois pedidos simultâneos do mesmo
    -- jogador passariam juntos pelo cooldown. Falhou adiante? devolve o valor anterior.
    self.lastCreatedAt[player.identifier] = now

    if (reportsRepository:countOpenByAuthor(player.identifier) >= ReportsConfig.maxOpenPerAuthor) then
        self.lastCreatedAt[player.identifier] = lastAt
        return false, 'too_many_open'
    end

    local report = reportsRepository:create(player.identifier, player.name, message)
    if (not report) then
        self.lastCreatedAt[player.identifier] = lastAt
        self.log:error('insert falhou autor=%s', player.identifier)
        return false, 'insert_failed'
    end

    local payload = report:toPayload()
    self:notifyStaff(payload)
    return true, 'ok', payload
end

---@param actor string quem fechou (identifier, 'console', 'resource:<nome>')
---@return boolean ok, string code, table|nil ReportPayload
function ReportsService:close(id, actor)
    id = math.floor(tonumber(id) or 0)
    if (id < 1) then
        return false, 'invalid_id'
    end

    local report = reportsRepository:findById(id)
    if (not report) then
        return false, 'not_found'
    end

    if (not report:isOpen() or not reportsRepository:close(id, actor)) then
        return false, 'already_closed'
    end

    report:markClosed(actor)
    local payload = report:toPayload()

    local authorSource = playerRegistry:getSourceByIdentifier(report.authorIdentifier)
    if (authorSource) then
        TriggerClientEvent(EVENT.REPORT_CLOSED, authorSource, payload)
    end
    return true, 'ok', payload
end

reportsService = ReportsService()
```

### `server/modules/reports/reports.commands.lua`

```lua
--- /closereport <id> — staff ou console.
CreateCommand(ReportsConfig.commands.close, function(ctx, args)
    local ok, code, report = reportsService:close(args[1], ctx.actor)
    if (not ok) then
        commandManager:reply(ctx, ('Falhou: %s'):format(code))
        return
    end

    commandManager:reply(ctx, ('Report #%s fechado.'):format(report.id))
end, { console = true, permission = ReportsConfig.permission })
```

### `server/api/rpc.lua` (acrescentar)

```lua
RPC.register('reports.create', withPlayer(function(player, args)
    return reportsService:create(player, type(args) == 'table' and args.message or nil)
end))
```

### `client/modules/reports/reports.api.lua`

```lua
--- Ponte RPC client → server. Toda chamada yielda — usar dentro de thread.
ReportsApi = class()

---@param message string
function ReportsApi:create(message)
    return RPC.await('reports.create', { message = message })
end

reportsApi = ReportsApi()
```

### `client/modules/reports/reports.commands.lua`

```lua
--- /report <mensagem> — cria um report via RPC. O server valida tudo de novo.
RegisterCommand(ReportsConfig.commands.create, function(_, args)
    CreateThread(function()
        local ok, code, report = reportsApi:create(table.concat(args, ' '))
        local messages = ReportsConfig.messages

        if (not ok) then
            Notify(messages.errors[code] or messages.fallbackError:format(code))
            return
        end

        Notify(messages.sent:format(report.id))
    end)
end, false)
```

### `client/modules/reports/reports.events.lua`

```lua
--- Staff: report novo (o server só envia para quem tem a permissão).
RegisterNetEvent(EVENT.REPORT_CREATED, function(report)
    if (type(report) ~= 'table') then
        return
    end

    Notify(ReportsConfig.messages.staffNew:format(report.id, report.authorName, report.message))
end)

--- Autor: o report dele foi fechado.
RegisterNetEvent(EVENT.REPORT_CLOSED, function(report)
    if (type(report) ~= 'table') then
        return
    end

    Notify(ReportsConfig.messages.closed:format(report.id))
end)
```
