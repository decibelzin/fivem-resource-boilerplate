# prompts.md — pedidos prontos para o agente

Abra o agente **na raiz do resource** (onde está o `AGENTS.md`). Troque o que está entre `<>`.

## Transformar o boilerplate num script novo

```text
Este repo é um boilerplate. Transforme-o no resource `<nome>`: <o que o script faz, regras de negócio,
quem pode o quê, o que persiste>.
Siga AGENTS.md e docs/playbooks/new-module.md, copiando o formato de server/modules/reports/.
- Atualize fxmanifest (name/description) e troque o prefixo `boilerplate_` das tabelas por `<nome>_`.
- Crie os módulos necessários; quando o primeiro módulo real estiver pronto, remova o exemplo `reports`
  inteiro (config, schema, server, client, api, EVENT e docs/api.md).
- Framework do servidor: <standalone | vRP | QBox | ESX> — adapte só server/lib/framework.bridge.lua.
Pergunte só decisões de produto, não de estilo.
```

## Módulo novo

```text
Crie o módulo `<modulo>` seguindo docs/playbooks/new-module.md: <regras>.
Só as camadas necessárias. API nova em server/api/ + docs/api.md no mesmo turno.
```

## Refatorar script legado para o padrão

```text
Refatore `<arquivo|pasta>` seguindo docs/patterns.md (checklist §11), mantendo o comportamento.
Liste o que mudou de contrato (eventos/exports) antes de mexer.
```

## Portar para a framework do servidor

```text
Porte server/lib/framework.bridge.lua para <vRP | QBox | ESX>: identifier estável, nome e permissão.
Nada fora do bridge pode chamar a framework diretamente.
```

## Review antes do commit

```text
Revise o diff contra docs/patterns.md §6 e §12: broadcast -1, payload do client sem validação, await
antes de marcar cooldown/lock, SQL fora do repository, texto/número mágico fora da config, export/RPC
sem linha em docs/api.md. Aponte arquivo:linha.
```
