# prompts.md — pedidos prontos para o agente

Abra o agente **na raiz do resource** (onde está o `AGENTS.md`). Troque o que está entre `<>`.

## Transformar o boilerplate num script novo

```text
Este repo é um boilerplate. Transforme-o no resource `<nome>`: <o que o script faz, regras de negócio,
quem pode o quê, o que persiste>.
Siga AGENTS.md e docs/playbooks/new-module.md, copiando o formato do exemplo `reports` do playbook.
- Atualize fxmanifest (name/description) e use o prefixo `<nome>_` nas tabelas.
- Crie os módulos necessários. O que precisar da framework do servidor vira função na ponte
  (Bridge.x com default standalone + Framework.x), nunca chamada direta.
Pergunte só decisões de produto, não de estilo.
```

## Módulo novo

```text
Crie o módulo `<modulo>` seguindo docs/playbooks/new-module.md: <regras>.
Só as camadas necessárias. API nova em server/api/ + docs/api.md no mesmo turno.
```

## Função nova na ponte

```text
O script precisa de <dinheiro | item | job | ...> da framework do servidor. Siga a seção "Feature que
precisa da framework" do playbook: Bridge.x em bridge/bridge.server.lua com default standalone e
comentário dizendo o que devolver, Framework.x no núcleo com as regras, linha na seção Ponte do
docs/api.md. Não cite nenhuma framework pelo nome.
```

## Refatorar script legado para o padrão

```text
Refatore `<arquivo|pasta>` seguindo docs/patterns.md (checklist §11), mantendo o comportamento.
Liste o que mudou de contrato (eventos/exports) antes de mexer.
```

## Review antes do commit

```text
Revise o diff contra docs/patterns.md §6 e §12: broadcast -1, payload do client sem validação, await
antes de marcar cooldown/lock, SQL fora do repository, texto/número mágico fora da config, export/RPC
sem linha em docs/api.md, framework chamada fora da ponte. Aponte arquivo:linha.
```
