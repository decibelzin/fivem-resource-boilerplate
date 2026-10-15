# decisions.md — porquês

Uma entrada por decisão de arquitetura: data, o que, porquê. A mais nova no topo.

## 2026-10-15 — Multi-framework com auto-detecção; identifier por personagem

O bridge virou contrato + adapters: `server/lib/framework.bridge.lua` define `Framework.*` (valida conta e
valor, fallback ACE, nome) e cada `server/bridge/<nome>.lua` (standalone, qbox, qbcore, esx, vrp) regista
uma factory. A escolha é feita uma vez no load — convar `<resource>_framework` ou `auto` por
`GetResourceState` (`qbx_core` primeiro: ele faz `provide 'qb-core'`). Só a factory escolhida corre: nenhum
código de framework ausente executa, os globs do manifest seguem order-independent e o mesmo resource
serve qualquer servidor sem editar código. Framework escolhida e parada → erro e sem `App.ready` (mesma
regra do oxmysql: verificar uma vez, logar, abortar — sem poll nem `dependency`).

`Framework.identifier` passou a ser **por personagem** (citizenid, identifier do ESX, Passport do vRP;
standalone segue com a license, porque não há personagem). Porquê: com multichar, dado de jogo (reports,
cooldown, inventário, progresso) pertence ao personagem — chavear pela license misturaria personagens da
mesma conta. Consequências: o personagem só existe depois da seleção, então o registry faz bind no
`Framework.onPlayerLoaded` (e unbind no logout/troca), não no `playerJoining`; trocar de framework ou
ligar/desligar multichar no ESX muda as chaves e o dado antigo fica órfão.

Dinheiro entrou no contrato com regras iguais em todas: contas `MONEY_ACCOUNT` (cash/bank), inteiro > 0,
nunca saldo negativo (`insufficient`, mesmo onde a framework aceitaria). vRP não tem doc oficial e os forks
são incompatíveis: o adapter segue o creative v5+ como ponto de partida, com `[confirmar]` em cada chamada
não verificada.

## 2026-10-14 — Raiz do repo = resource

Clonar para `resources/[scripts]/<nome>` e dar `ensure` tem de bastar. Docs ficam em `docs/` (o FiveM
ignora ficheiros que o manifest não lista).

## 2026-10-14 — Framework só no bridge

`server/lib/framework.bridge.lua` é o único ponto acoplado à framework (default standalone: license + ACE).
Portar para vRP/QBox/ESX é editar um ficheiro; services ficam testáveis e copiáveis entre servidores.
(Expandida em 2026-10-15: contrato + adapters em `server/bridge/`, escolha por convar/auto.)

## 2026-10-14 — Eventos prefixados por `GetCurrentResourceName()`

`EVENT.*` deriva do nome do resource: renomear a pasta não exige caçar strings e dois clones do
boilerplate nunca colidem. RPC já é isolado por resource na própria lib.

## 2026-10-14 — RPC valida pacote e resposta

A lib de RPC descarta pacotes malformados vindos do client e, no `awaitClient`, só aceita a resposta
do client que recebeu o pedido (anti-spoof entre jogadores).

## 2026-10-14 — Sem validador Lua automático

A sintaxe valida-se arrancando o servidor (consola sem erro de parse). Agente que não arrancou declara
isso em vez de afirmar que validou.
