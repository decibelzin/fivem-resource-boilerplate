# prompts.md — pedidos prontos para o agente

Abra o agente **na raiz do resource** (onde está o `AGENTS.md`). Troque o que está entre `<>`.

## Transformar o boilerplate num script novo

```text
Este repo é um boilerplate. Transforme-o no resource `<nome>`: <o que o script faz, regras de negócio,
quem pode o quê, o que persiste>.
Siga AGENTS.md e docs/playbooks/new-module.md, copiando o formato de server/modules/reports/.
- Atualize fxmanifest (name/description) e troque o prefixo `boilerplate_` das tabelas por `<nome>_`.
- Crie os módulos necessários; quando o primeiro módulo real estiver pronto, remova o exemplo `reports`
  inteiro (config, schema, server, client, api, EVENT, a entrada em FrameworkConfig.groups e docs/api.md).
- Framework do servidor: <auto | standalone | qbox | qbcore | esx | vrp> (convar `<nome>_framework`);
  grupos de staff em FrameworkConfig.groups. Nada fora de server/bridge/ chama a framework.
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

## Ajustar o adapter à versão da framework do servidor

```text
Ajuste server/bridge/<vrp | qbox | qbcore | esx>.lua à versão de <framework> deste servidor (código em
<caminho do resource da framework>): confira cada chamada, sobretudo as marcadas [confirmar], contra o
código real e corrija nome/argumento/retorno. Mantenha a interface do adapter descrita em
server/lib/framework.bridge.lua e o identifier por personagem. Nada fora de server/bridge/ chama a framework.
```

## Review antes do commit

```text
Revise o diff contra docs/patterns.md §6 e §12: broadcast -1, payload do client sem validação, await
antes de marcar cooldown/lock, SQL fora do repository, texto/número mágico fora da config, export/RPC
sem linha em docs/api.md. Aponte arquivo:linha.
```
