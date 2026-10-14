# decisions.md — porquês

Uma entrada por decisão de arquitetura: data, o que, porquê. A mais nova no topo.

## 2026-10-14 — Raiz do repo = resource

Clonar para `resources/[scripts]/<nome>` e dar `ensure` tem de bastar. Docs ficam em `docs/` (o FiveM
ignora ficheiros que o manifest não lista).

## 2026-10-14 — Framework só no bridge

`server/lib/framework.bridge.lua` é o único ponto acoplado à framework (default standalone: license + ACE).
Portar para vRP/QBox/ESX é editar um ficheiro; services ficam testáveis e copiáveis entre servidores.

## 2026-10-14 — Eventos prefixados por `GetCurrentResourceName()`

`EVENT.*` deriva do nome do resource: renomear a pasta não exige caçar strings e dois clones do
boilerplate nunca colidem. RPC já é isolado por resource na própria lib.

## 2026-10-14 — RPC valida pacote e resposta

A lib de RPC descarta pacotes malformados vindos do client e, no `awaitClient`, só aceita a resposta
do client que recebeu o pedido (anti-spoof entre jogadores).

## 2026-10-14 — Sem validador Lua automático

A sintaxe valida-se arrancando o servidor (consola sem erro de parse). Agente que não arrancou declara
isso em vez de afirmar que validou.
