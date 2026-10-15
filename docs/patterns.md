# patterns.md — padrão de código

Este doc é o alvo de qualquer feature ou refatoração: *"faça X seguindo docs/patterns.md"* deve bastar.
Referência: o módulo de exemplo `reports`, completo, em `docs/playbooks/new-module.md` (o template traz
só a estrutura — nenhum módulo de feature).

## 1. Classes e instâncias

```lua
-- Domínio (estado e/ou regras) = class() + instância global lowerCamel no fim do ficheiro.
ReportsService = class()

function ReportsService:__init()
    self.log = Log.scope('reports')
    self.lastCreatedAt = {}
end

function ReportsService:close(id, actor)
    -- early return em guard clauses, nunca pirâmide de if
    id = math.floor(tonumber(id) or 0)
    if (id < 1) then
        return false, 'invalid_id'
    end
    ...
    return true, 'ok', payload
end

reportsService = ReportsService()
```

- Métodos sempre com `:`; condições entre parênteses: `if (not player) then`.
- 4 espaços, aspas simples, `('%s #%d'):format(a, b)` em vez de concatenação com `..`.
- `__init` só quando há estado. Sem estado e sem regra não é classe — use tabela de funções (ex.: `Framework`).
- Herança: `Child = class(Parent)`.
- Entidades (`Report`, `OnlinePlayer`) expõem **camelCase**; conversão de snake_case acontece UMA vez,
  no `:applyRow` chamado pelo repository.
- `---@param` / `---@return` nos métodos públicos; `---` de cabeçalho no topo do ficheiro diz o papel dele.

## 2. Nomes

| Coisa | Padrão | Exemplo |
|-------|--------|---------|
| Ficheiro | `nome.papel.lua` (ponto) | `reports.service.lua`, `player.registry.lua` |
| Classe | PascalCase | `ReportsService` |
| Instância global | lowerCamel | `reportsService` |
| Config do módulo | `<Modulo>Config` em `shared/config/<modulo>.lua` | `ReportsConfig` |
| Enum | UPPER_SNAKE | `REPORT_STATUS.OPEN` |
| Código de retorno | snake_case | `'too_many_open'`, `'rpc_timeout'` |
| Tabela / coluna DB | snake_case, tabela prefixada pelo resource | `boilerplate_reports.closed_at` |
| Campo de entidade/payload | camelCase | `authorName`, `createdAt` |
| Evento de rede | `EVENT.X` = `<resource>:<modulo>:<acao>` | `EVENT.SHOP_OPENED` |
| RPC | `<modulo>.<verboCamel>` | `reports.create` |
| ACE | `<modulo>.<acao>` | `reports.manage` |
| Convar | `<resource>_<tema>` | `<resource>_log_level` |
| Chave de texto | `<modulo>.<chaveCamel>` · erro: `<modulo>.errors.<code>` | `reports.staffNew` |

## 3. Retornos e erros

- Tudo que pode falhar retorna **`ok:boolean, code:string, data?`**. Nada de `error()` para fluxo de negócio.
- O caller decide o que fazer com o `code`; services não imprimem erro de validação (só logam falha inesperada).
- `data` em erro é permitido quando ajuda o caller (`'cooldown', { retryIn = 30 }`).
- `pcall` só em fronteiras (RPC já faz; transações; chamadas a outros resources).
- Escritas não críticas (auditoria, telemetria, last_seen) → `Util.background('label', fn)` — nunca bloqueiam.

## 4. Camadas — quem pode fazer o quê

| Camada | Pode | Não pode |
|--------|------|----------|
| `*.schema.lua` | DDL (`Schema.table/column/seed`) | Lógica, SELECT |
| `*.repository.lua` | SQL, hidratar entidades | Regra de negócio, eventos |
| `*.entity.lua` | Dados + regras puras do próprio objeto (`isOpen`) | SQL, rede |
| `*.service.lua` | Regras, chamar repos/outros services, eventos unicast | SQL se o módulo TEM repository |
| `*.events.lua` / `*.commands.lua` | Validar input, delegar a service, responder | Regra de negócio, SQL |
| `server/api/*.lua` | Expor exports/RPC delegando a services | Qualquer lógica |
| `client/modules/*/*.api.lua` | Wrapper de `RPC.await` | Regra de negócio |

Adapters (`events`/`commands`/`api`) são **finos e lineares** — sem classes, sem helpers desnecessários.
Módulo pequeno sem repository pode ter SQL no próprio service — mas SQL **nunca** sai do módulo dono.

## 5. Simplicidade primeiro

- Helper local só se reutilizado em **≥2 lugares** ou se esconder lógica real. Senão, inline.
- Um log no ponto da falha; sem camadas de log duplicadas para o mesmo erro.
- Não criar manager/factory/wrapper para glue de 3 linhas.
- Comentário explica **porquê**, não o quê. Código autoexplicativo > comentário.
- Idioma dos comentários: **inglês** no que o comprador vê (`bridge/`, `shared/config/`,
  `fxmanifest.lua`); pt-BR no resto (código criptografado e docs).
- Camadas só existem quando há o que separar: script minúsculo pode ser só `service` + `commands`.

## 6. Rede e confiança

- Server → client: **unicast sempre** (`TriggerClientEvent(evt, src, ...)`). `-1` proibido — monte a
  audiência no server (ver `notifyStaff` no exemplo do playbook: loop em `GetPlayers()` filtrando com
  `Framework.hasPermission` — o cache de jogadores só tem quem já usou o script).
- **Payload mínimo server → client.** A config é shared — o client já a tem. Tudo que é estático (texto,
  label, definição de item/loja/local, ícone, preço de exibição) o client resolve pela chave/id; pela rede
  vai só a chave/id e o que é dinâmico (nome do autor, quantidade, mensagem digitada):
  - mensagem ao jogador → `NotifyPlayer(src, 'reports.closed', id)`, nunca o texto pronto;
  - evento próprio → `TriggerClientEvent(EVENT.X, src, shopId, stock)`, nunca a definição da loja;
  - entidade nunca vai inteira — só os campos que o destinatário usa;
  - retorno de RPC → `code` + o mínimo de `data` (o id, não a entidade); o client mostra
    `Text(('<modulo>.errors.%s'):format(code))`.
- Client → server com retorno: `RPC.await(name, args)` dentro de `CreateThread` (yielda). Fire-and-forget
  simples pode ser `TriggerServerEvent` + `RegisterNetEvent` num `*.events.lua`.
- **`source` é confiável; os argumentos não.** Valide tipo (`type(args) == 'table'`), tamanho
  (`utf8.len`), range e permissão no server. Nunca receba do client preço, quantidade de recompensa,
  coordenada de spawn de item ou "sou admin".
- Handler que faz `await` (MySQL, RPC) **cede a vez**: dois pedidos do mesmo jogador podem intercalar.
  Marque o estado (cooldown, lock, "em andamento") **antes** do primeiro await e desfaça se falhar.
- Estado replicado para clients (statebag) é só leitura do lado deles — efeito sensível decide-se no server.

## 7. Arranque, fxmanifest e dependências

- Sem `dependency` entre resources — a ordem no `server.cfg` é o contrato (`ensure oxmysql` antes).
- Sem poll (`while ... Wait()`) esperando outro resource: verificar uma vez, logar e abortar. Quem
  consome este resource usa `exports.<resource>:IsReady()` ou escuta `EVENT.READY`.
- O manifest usa globs (`server/modules/**/*.lua`): **ficheiro novo em módulo não exige tocar no manifest**.
  Por isso o código de módulo é order-independent: **nunca** use a instância de outro módulo no top-level
  do ficheiro — só dentro de funções (runtime). `CreateCommand`/`RPC.register`/`Schema.*` no top-level
  são OK (libs carregam antes).
- Handlers checam `App.ready`. `CreateCommand` e os wrappers `guard`/`withPlayer` do `rpc.lua` já checam;
  `RegisterNetEvent` cru tem de checar à mão.
- Restart a quente funciona sem varrer ninguém: jogadores entram no cache sob demanda (`playerRegistry:get`
  resolve pela ponte no primeiro uso). Nunca faça trabalho por jogador para todos os online no arranque.

## 8. Persistência

- Tabelas no `<modulo>.schema.lua`: `CREATE TABLE IF NOT EXISTS`, InnoDB, `utf8mb4_unicode_ci`,
  **prefixo do resource** no nome. Coluna nova = `Schema.column`. Seed idempotente = `INSERT IGNORE`.
- Sem migração de dados elaborada: DDL idempotente; o schema nasce sozinho no arranque.
- Jogador referenciado pelo `Framework.identifier` (por personagem) — sem FK para tabelas de outra framework.
- Nunca SQL nas tabelas de outra framework/resource: o que o script precisa dela vem pela ponte.
- oxmysql devolve DATETIME em **milissegundos** → `Util.datetimeToUnix` no `:applyRow`.
- Mutação que muda algo de um jogador online: persistir **e** atualizar a RAM/avisar o client.
- `LIKE` com input do jogador: escapar `% _ \` antes.
- Query por item dentro de loop → uma query agregada antes do loop, consulta ao mapa por chave.

## 9. Config

- Tudo que um humano pode querer ajustar vive em `shared/config/<modulo>.lua`: limites, cooldowns,
  nomes de comando, ACE, definições estáticas indexadas por id.
- Texto do jogador vive em `Messages.<modulo>` no mesmo ficheiro (chave → texto; erros indexados pelo
  `code`). Server e client resolvem a mesma chave com `Text(key, ...)`; textos do núcleo em `Messages.core`.
- Enum partilhado client/server vive junto da config do módulo.
- Valor que muda sem deploy → convar lida por função na config (`GetConvar(...)`).

## 10. Framework (ponte aberta)

- O núcleo **não conhece framework nenhuma** e nunca a cita. Quem liga a do servidor é o comprador, em
  `bridge/bridge.server.lua` e `bridge/bridge.client.lua` — os únicos ficheiros de código abertos no
  escrow (`escrow_ignore`, junto com `shared/config/`).
- Ponte = funções pequenas com **default standalone** (o script roda sem configurar) que devolvem valores
  simples (string, número, boolean). O comprador troca o corpo; nome, argumentos e retorno são contrato.
- O núcleo (`server/lib/framework.lua`) chama `Bridge.*` protegido (`pcall` + log), confere o tipo do
  retorno e converte para o padrão do script. Os módulos só usam `Framework.*` ou `player:hasPermission`.
- **`Framework.identifier` é por personagem**: dado de jogo pertence ao personagem, não à conta.
- Dado de jogador carrega **sob demanda** (primeiro uso, cache em RAM) e é invalidado em
  `Framework.onCharacterChanged` e `playerDropped`. Nunca carregue de todos no login, no arranque ou no
  restart: o custo da ponte do comprador é desconhecido e servidor grande tem milhares online.
- Permissão = ACE (vale sempre) **ou** `Bridge.hasPermission` (o comprador só soma).
- Feature que precisa da framework (dinheiro, item, job…) = função nova na ponte, só no script que usa:
  `Bridge.x` com default + `Framework.x` no núcleo + linha em `docs/api.md` (receita no playbook).
- Contrato publicado não muda: renomear ou mudar retorno de `Bridge.*` quebra o ficheiro do comprador no
  update. Função nova entra com default e no changelog.
- Client: `Notify(message)` (default chat) é a ponte do client.

## 11. Checklist de refatoração (aplicar nesta ordem)

1. Ficheiro no lugar certo? (módulo/camada — §4) Nome com ponto?
2. Tabelas `X = {}` com estado/regras → `class()` + instância global.
3. Retornos → `ok, code, data?`; códigos snake_case.
4. SQL fora de repository → mover para repository (ou schema).
5. snake_case vazando da DB para cima → confinar no `:applyRow`.
6. Broadcasts `-1` → unicast com audiência montada no server.
7. Polls entre resources → ordem do `server.cfg` + log de erro.
8. Chamadas diretas à framework → função na ponte (`Bridge.x` + `Framework.x`).
9. Números/textos mágicos → config.
10. Helpers de uso único → inline. Comentários de "o quê" → apagar.
11. Atualizar `docs/api.md` se a superfície mudou.

## 12. Antipadrões (erros que agentes cometem — não repita)

| ❌ Errado | ✅ Certo |
|----------|---------|
| `exports.meu:GetAlgo(...)` inventado | Conferir em `docs/api.md` — se não está lá, não existe |
| `TriggerClientEvent('x', -1, data)` | Loop em `GetPlayers()` com unicast para a audiência |
| `while not exports.x:IsReady() do Wait(100) end` | Checar uma vez e abortar com log, ou escutar o evento READY |
| `RPC.await(...)` no top-level do ficheiro | Dentro de `CreateThread` ou NUI callback (yielda) |
| Instância de outro módulo no top-level | Referenciar só dentro de funções (load order alfabético) |
| `Service = {}` com estado | `Service = class()` + instância global |
| `exports(...)` dentro do service | Só em `server/api/exports.lua` |
| `MySQL.query(...)` no `*.commands.lua` | Delegar ao service → repository |
| `return nil` / `error('sem saldo')` em regra de negócio | `return false, 'insufficient'` |
| `RegisterNetEvent('x:darDinheiro', function(valor) ...)` | Server calcula o valor; client só pede a ação |
| Cooldown marcado depois do `MySQL.*.await` | Marcar antes do primeiro await (pedidos intercalam) |
| Export/função da framework chamado no service | Função na ponte; o service usa `Framework.x` |
| Carregar dado de todos os online no arranque/restart/login | Sob demanda no primeiro uso, invalidado em `onCharacterChanged`/`playerDropped` |
| `if #msg > 300` com texto pt-BR | `utf8.len(msg)` — `#` conta bytes, acento vale 2 |
| `'Aguarde 2 minutos'` hardcoded no service | Texto em `Messages.<modulo>`, indexado pelo `code` |
| `TriggerClientEvent(evt, src, report)` / texto pronto / definição da config na payload | Chave/id + só o dinâmico; o client resolve na config (`NotifyPlayer`, `Text`) |
| Condição morta / checagem repetida no mesmo item | Remover; guardar o resultado num local e reusar |
| Editar o fxmanifest para adicionar ficheiro de módulo | Globs já cobrem — só criar o ficheiro |
