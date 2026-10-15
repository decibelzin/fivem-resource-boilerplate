# api.md — superfície pública

> Fonte de verdade de exports, RPC, eventos, comandos, convars e da ponte. **Se não está aqui, não existe.**
> Mudou `server/api/*.lua`, `EVENT`, um comando, uma convar ou a ponte? Atualize este ficheiro no mesmo commit.

Retorno de tudo que pode falhar: **`ok:boolean, code:string, data?`**. Falhas de transporte do RPC chegam
com `ok = nil`: `rpc_timeout` · `rpc_unknown_method` · `rpc_handler_error`.

## Exports (server → server)

| Export | Args | Retorno |
|--------|------|---------|
| `IsReady()` | — | `boolean` |

## RPC (client → server)

| RPC | Args | Retorno | Códigos de erro |
|-----|------|---------|-----------------|

_Nenhum ainda._

## Eventos

| Evento | Direção | Audiência | Payload |
|--------|---------|-----------|---------|
| `EVENT.READY` (`<resource>:ready`) | server local | outros resources | — |

## Comandos

| Comando | Lado | Acesso |
|---------|------|--------|

_Nenhum ainda._

## Convars (server.cfg)

| Convar | Valores | Default |
|--------|---------|---------|
| `<resource>_log_level` | `debug` · `info` · `warn` · `error` | `info` |

## Ponte (ficheiros abertos ao comprador)

Contrato estável entre versões: nome, argumentos e retorno não mudam; função nova entra com default.

| Função | Ficheiro | Default | Contrato |
|--------|----------|---------|----------|
| `Bridge.identifier(src)` | `bridge/bridge.server.lua` | license | id **estável do personagem** (string/número); `nil` = não carregado. Chamado uma vez por jogador (cache) |
| `Bridge.displayName(src)` | `bridge/bridge.server.lua` | nome do FiveM | string; `nil` = nome do FiveM. Chamado junto com o identifier |
| `Bridge.hasPermission(src, permission)` | `bridge/bridge.server.lua` | `false` | boolean, **somado** ao ACE (que vale sempre). Chamado com frequência — tem de ser barato |
| `Framework.characterChanged(src)` | chamado pela ponte | não chamado (standalone não tem personagem) | personagem carregou/trocou/logout → tira o jogador do cache |
| `Notify(message)` | `bridge/bridge.client.lua` | chat | mostra a mensagem ao jogador |

## Tipos

_Nenhum ainda._
