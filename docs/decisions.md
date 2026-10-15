# decisions.md — porquês

Uma entrada por decisão de arquitetura: data, o que, porquê. A mais nova no topo.
As decisões do projeto entram acima da base herdada do boilerplate.

## Base do boilerplate

- **Raiz do repo = resource.** Clonar para `resources/[scripts]/<nome>` e dar `ensure` tem de bastar.
  Docs ficam em `docs/` (o FiveM ignora ficheiros que o manifest não lista).
- **Framework só pela ponte aberta.** O núcleo não conhece framework nenhuma; o comprador liga a dele em
  `bridge/` (aberto no escrow), em funções pequenas com default standalone e valores simples. Porquê: cada
  servidor tem versão, fork e modificação próprios — um adapter pronto chutaria e quebraria em silêncio;
  quem conhece o servidor é quem o roda. O núcleo protege contra erro no código do comprador (`pcall` +
  log) e confere o retorno. Função de ponte publicada não muda de nome nem de retorno entre versões.
- **Identifier por personagem.** Dado de jogo pertence ao personagem, não à conta. Por isso o registry
  faz bind quando a ponte avisa "personagem carregado", não no `playerJoining`.
- **ACE vale sempre.** `add_ace` funciona em qualquer servidor; a ponte só soma permissões.
- **Eventos prefixados por `GetCurrentResourceName()`.** Renomear a pasta não exige caçar strings e dois
  resources feitos do boilerplate nunca colidem. RPC já é isolado por resource na própria lib.
- **RPC valida pacote e resposta.** Descarta pacotes malformados do client e, no `awaitClient`, só aceita
  a resposta do client que recebeu o pedido (anti-spoof entre jogadores).
- **Sem validador Lua automático.** A sintaxe valida-se arrancando o servidor (consola sem erro de
  parse). Agente que não arrancou declara isso em vez de afirmar que validou.
