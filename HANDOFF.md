# Handoff — Painel de Obras ETI (Secretaria de Educação do Pará)

Este arquivo é a continuidade do trabalho feito no Claude. Leia inteiro antes de mexer no código.

## Arquivos

- `proposta/index.html` — a prévia aprovada com ajustes. Visual "Prancheta de obra" (IBM Plex Sans), visão geral, cronograma, fichas de escola, editor de etapas. Hoje ela roda com dados de exemplo (`dados.js`, `amostra.js`).
- `proposta/dados.js` — os 22 serviços e 144 etapas reais, lidos do Supabase (projeto `xmhlnmxsmwrhnblxtkqu`). Todos com `pct` 0.
- `proposta/amostra.js` — gera datas previstas, % e medições de exemplo. **Remover ao ligar no banco real.**
- `proposta/charts.js` — biblioteca de gráficos SVG (sem dependências). Manter.
- `proposta/logo.png` — logo "Secretaria de Educação · Governo do Pará", enviado pelo usuário.
- `historico.sql` — cria a tabela `medicoes` (histórico). Já corrigido: `servico_id` é `text`.
- O arquivo original `index.html` (com Supabase e login) está em `Downloads` e não foi alterado.

## Pedidos do usuário (todos ainda não feitos)

1. **Remover o login.** Sistema único, para todos. Não há mais "Entrar", "Sair" nem tela de senha. Ver o alerta de segurança abaixo.
2. **Zerar todos os % de avanço dos serviços.** Todas as etapas com `pct = 0`, `paralisado = false`, `obs = ''`. O usuário preenche do zero. Limpar também a tabela `medicoes`. **Esta é uma ação destrutiva no banco: confirmar com o usuário antes de executar o UPDATE/DELETE.**
3. **Cronograma final em 20/12/2026.** Trocar o prazo de 31/10/2026 por 20/12/2026 em todo lugar: a constante `PRAZO` e o texto `PRAZO_TXT` ("20 de dezembro de 2026"), o contador de dias, o rótulo "Prazo do Plano ETI" e os textos "após o prazo" / "terminam depois do prazo". Os exemplos de `amostra.js` também devem usar 20/12 (ou ser removidos).
4. **Logo no canto superior esquerdo.** Colocar `logo.png` no topo esquerdo da barra lateral, no lugar do quadrado azul com a casinha. A logo tem fundo branco; dar a ela um espaço de respiro e tamanho em torno de 180–200px de largura. No celular, mostrar na barra superior.
5. **Marcar etapa paralisada com observação, em destaque no painel principal.**
   - Cada etapa ganha um botão/chave "Paralisada". Ao marcar, abre um campo obrigatório "Justificativa do problema".
   - Essas etapas aparecem num bloco **"Paralisadas — solução urgente"** no topo da visão geral, acima da curva, com cor de alerta, nome da etapa, escola, justificativa e data em que foram marcadas.
   - Uma etapa paralisada não conta como concluída. Desmarcar a pausa limpa a justificativa só depois de confirmar.
   - Hoje existe `paralisado` no nível do **serviço**. Trocar ou complementar por `paralisado` e `justificativa` no nível da **etapa**.

## Banco (Supabase)

Rodar no SQL Editor, nesta ordem:

1. `historico.sql` (tabela `medicoes`).
2. Adicionar em `etapas`: `inicio date`, `fim date`, `paralisada boolean default false`, `justificativa text`, `paralisada_em timestamptz`.
3. Para o item 2 (zerar): `update etapas set pct = 0;` `update servicos set paralisado = false, obs = '';` `delete from medicoes;` — **confirmar antes.**

## Alerta de segurança (importante)

Tirar o login e manter a chave `anon` significa que **qualquer pessoa com o link pode alterar o banco.** Hoje as políticas de RLS só permitem escrita para usuários logados. Para remover o login, é preciso trocar as políticas para permitir `insert/update/delete` com a chave anon, o que deixa o painel aberto para edição por quem tiver o link. Antes de publicar, decidir com o usuário: (a) aceitar isso, ou (b) manter um único login compartilhado do órgão. Não publicar sem essa decisão.

## Pendências de decisão do usuário

- Os ajustes à direção visual que o usuário disse ter ("Aprovo com ajustes") ainda não foram especificados. Perguntar o que mudar antes de finalizar o visual.
- Os nomes de escolas, serviços e etapas são os do banco. Não inventar dados de proof/cliente.

## Prompt para colar no Antigravity

> Continue o projeto em `proposta/` seguindo `HANDOFF.md`. Use `proposta/index.html` como base, mantenha a visual atual e o `charts.js`. Ligue o painel ao Supabase (URL e chave anon) e remova `amostra.js`, lendo os dados reais. Implemente os cinco pedidos do arquivo, na ordem: (1) sem login, (2) zerar, (3) prazo 20/12/2026, (4) logo `logo.png` no canto superior esquerdo, (5) etapa paralisada com justificativa e destaque no painel principal. Antes de rodar UPDATE/DELETE no banco, pergunte. Ao final, rode `node scripts/...` não se aplica: abra a página no navegador, teste concluir etapa, marcar paralisada, e as três larguras (1440, 768, 390px).
