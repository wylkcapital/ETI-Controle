-- ====================================================================
-- Script Completo e Autocontido - Banco de Dados Supabase (Plano ETI 2026)
-- Pode ser executado em um projeto NOVO ou no projeto EXISTENTE.
-- ====================================================================

-- 1. Criação da tabela de serviços (caso ainda não exista)
create table if not exists public.servicos (
  id text primary key,
  escola text not null,
  origem text default 'Plano ETI 2026',
  prioridade integer default 1,
  servico text not null,
  descricao text default '',
  tipo text default '',
  urgente boolean default false,
  paralisado boolean default false,
  obs text default '',
  atualizado_em timestamptz default now(),
  atualizado_por text
);

-- 2. Criação da tabela de etapas (caso ainda não exista)
create table if not exists public.etapas (
  id bigint primary key,
  servico_id text not null references public.servicos(id) on delete cascade,
  ordem integer not null,
  nome text not null,
  peso numeric not null,
  pct numeric default 0,
  inicio date,
  fim date,
  paralisada boolean default false,
  justificativa text,
  paralisada_em timestamptz
);
create index if not exists etapas_servico_ordem on public.etapas (servico_id, ordem);

-- Se a tabela etapas já existia sem as novas colunas, adiciona-as:
alter table public.etapas add column if not exists inicio date;
alter table public.etapas add column if not exists fim date;
alter table public.etapas add column if not exists paralisada boolean default false;
alter table public.etapas add column if not exists justificativa text;
alter table public.etapas add column if not exists paralisada_em timestamptz;

-- 3. Criação da tabela de medições (histórico de alterações)
create table if not exists public.medicoes (
  id bigserial primary key,
  servico_id text not null references public.servicos(id) on delete cascade,
  etapa text,
  de numeric,
  para numeric,
  pct numeric,
  detalhes jsonb not null default '[]',
  usuario text,
  em timestamptz not null default now()
);
create index if not exists medicoes_servico_em on public.medicoes (servico_id, em);

-- 4. Habilitar Realtime
do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'servicos') then
    alter publication supabase_realtime add table public.servicos;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'etapas') then
    alter publication supabase_realtime add table public.etapas;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'medicoes') then
    alter publication supabase_realtime add table public.medicoes;
  end if;
end $$;

-- 5. Políticas de RLS (Leitura e Escrita Públicas para chave anon - sem login)
alter table public.servicos enable row level security;
drop policy if exists "servicos leitura publica" on public.servicos;
drop policy if exists "servicos escrita publica" on public.servicos;
drop policy if exists "servicos_leitura" on public.servicos;
drop policy if exists "servicos_escrita" on public.servicos;
create policy "servicos leitura publica" on public.servicos for select using (true);
create policy "servicos escrita publica" on public.servicos for all using (true) with check (true);

alter table public.etapas enable row level security;
drop policy if exists "etapas leitura publica" on public.etapas;
drop policy if exists "etapas escrita publica" on public.etapas;
drop policy if exists "etapas_leitura" on public.etapas;
drop policy if exists "etapas_escrita" on public.etapas;
create policy "etapas leitura publica" on public.etapas for select using (true);
create policy "etapas escrita publica" on public.etapas for all using (true) with check (true);

alter table public.medicoes enable row level security;
drop policy if exists "medicoes leitura publica" on public.medicoes;
drop policy if exists "medicoes insert logado" on public.medicoes;
drop policy if exists "medicoes escrita publica" on public.medicoes;
create policy "medicoes leitura publica" on public.medicoes for select using (true);
create policy "medicoes escrita publica" on public.medicoes for all using (true) with check (true);

-- 6. Inserção / Carga inicial dos 22 Serviços (se não existirem)
insert into public.servicos (id, escola, origem, prioridade, servico, descricao, tipo, urgente, paralisado, obs)
values ('e01', 'E.E. Manoel de Jesus Moraes', 'Plano ETI 2026', 1, 'Climatização das salas', 'Intervenções necessárias para viabilizar a climatização dos ambientes de ensino.', 'Climatização', false, false, '')
on conflict (id) do nothing;
insert into public.servicos (id, escola, origem, prioridade, servico, descricao, tipo, urgente, paralisado, obs)
values ('e02', 'E.E. Manoel de Jesus Moraes', 'Plano ETI 2026', 2, 'Reforma da quadra com cobertura', 'Reforma do espaço esportivo, com execução ou recuperação da cobertura.', 'Quadra', false, false, '')
on conflict (id) do nothing;
insert into public.servicos (id, escola, origem, prioridade, servico, descricao, tipo, urgente, paralisado, obs)
values ('e03', 'E.E. Manoel de Jesus Moraes', 'Plano ETI 2026', 3, 'Manutenção do bloco administrativo', 'Adequações e serviços de manutenção no bloco administrativo.', 'Reforma', false, false, '')
on conflict (id) do nothing;
insert into public.servicos (id, escola, origem, prioridade, servico, descricao, tipo, urgente, paralisado, obs)
values ('e04', 'E.E. Oneide Tavares', 'Plano ETI 2026', 1, 'Ampliação do refeitório e da cozinha', 'Ampliação e adequação dos espaços de alimentação para a jornada ampliada.', 'Ampliação', false, false, '')
on conflict (id) do nothing;
insert into public.servicos (id, escola, origem, prioridade, servico, descricao, tipo, urgente, paralisado, obs)
values ('e05', 'E.E. Oneide Tavares', 'Plano ETI 2026', 2, 'Reforma dos banheiros', 'Recuperação e adequação das instalações sanitárias.', 'Reforma', false, false, '')
on conflict (id) do nothing;
insert into public.servicos (id, escola, origem, prioridade, servico, descricao, tipo, urgente, paralisado, obs)
values ('e06', 'E.E. Oneide Tavares', 'Plano ETI 2026', 3, 'Cobertura da quadra', 'Execução da cobertura da quadra esportiva.', 'Quadra', false, false, '')
on conflict (id) do nothing;
insert into public.servicos (id, escola, origem, prioridade, servico, descricao, tipo, urgente, paralisado, obs)
values ('e07', 'E.E. Dilma Catete', 'Plano ETI 2026', 1, 'Cobertura da quadra', 'Execução ou adequação da cobertura da quadra esportiva.', 'Quadra', false, false, '')
on conflict (id) do nothing;
insert into public.servicos (id, escola, origem, prioridade, servico, descricao, tipo, urgente, paralisado, obs)
values ('e08', 'E.E. Dilma Catete', 'Plano ETI 2026', 2, 'Recuperação de bloco com cinco salas', 'Bloco desativado com cerca de cinco salas; foco em forro e instalações elétricas.', 'Reforma', false, false, '')
on conflict (id) do nothing;
insert into public.servicos (id, escola, origem, prioridade, servico, descricao, tipo, urgente, paralisado, obs)
values ('e09', 'E.E. Dilma Catete', 'Plano ETI 2026', 3, 'Ampliação do refeitório', 'Ampliação do espaço de atendimento da alimentação escolar.', 'Ampliação', false, false, '')
on conflict (id) do nothing;
insert into public.servicos (id, escola, origem, prioridade, servico, descricao, tipo, urgente, paralisado, obs)
values ('e10', 'E.E. José Maria de Moraes', 'Plano ETI 2026', 1, 'Recuperação do prédio de laboratório', 'Recuperação e adequação do prédio do laboratório, hoje sem uso adequado.', 'Reforma', false, false, '')
on conflict (id) do nothing;
insert into public.servicos (id, escola, origem, prioridade, servico, descricao, tipo, urgente, paralisado, obs)
values ('e11', 'E.E. José Maria de Moraes', 'Plano ETI 2026', 2, 'Cobertura e arquibancada da quadra', 'Cobertura da quadra e adequação ou implantação de arquibancada.', 'Quadra', false, false, '')
on conflict (id) do nothing;
insert into public.servicos (id, escola, origem, prioridade, servico, descricao, tipo, urgente, paralisado, obs)
values ('e12', 'E.E. José Maria de Moraes', 'Plano ETI 2026', 3, 'Adequação do bloco administrativo', 'Manutenção e adequação do setor administrativo e ambientes de apoio.', 'Reforma', false, false, '')
on conflict (id) do nothing;
insert into public.servicos (id, escola, origem, prioridade, servico, descricao, tipo, urgente, paralisado, obs)
values ('e13', 'E.E. João Paulo', 'Plano ETI 2026', 1, 'Cobertura da quadra, vestiário e arquibancada', 'Cobertura da quadra e espaços complementares: vestiário e arquibancada.', 'Quadra', false, false, '')
on conflict (id) do nothing;
insert into public.servicos (id, escola, origem, prioridade, servico, descricao, tipo, urgente, paralisado, obs)
values ('e14', 'E.E. João Paulo', 'Plano ETI 2026', 2, 'Reforma dos banheiros', 'Recuperação e adequação das instalações sanitárias.', 'Reforma', false, false, '')
on conflict (id) do nothing;
insert into public.servicos (id, escola, origem, prioridade, servico, descricao, tipo, urgente, paralisado, obs)
values ('e15', 'E.E. João Paulo', 'Plano ETI 2026', 3, 'Reforma da copa/cozinha', 'Melhoria e adequação dos ambientes de preparo e apoio à alimentação.', 'Reforma', false, false, '')
on conflict (id) do nothing;
insert into public.servicos (id, escola, origem, prioridade, servico, descricao, tipo, urgente, paralisado, obs)
values ('e16', 'E.E. Prof. Renato Pinheiro Conduru', 'Plano ETI 2026', 1, 'Fechamento de 12 salas para climatização', 'Adequações físicas para permitir a climatização de cerca de 12 salas.', 'Climatização', false, false, '')
on conflict (id) do nothing;
insert into public.servicos (id, escola, origem, prioridade, servico, descricao, tipo, urgente, paralisado, obs)
values ('e17', 'E.E. Prof. Renato Pinheiro Conduru', 'Plano ETI 2026', 2, 'Reforma do bloco administrativo', 'Recuperação e adequação dos ambientes administrativos.', 'Reforma', false, false, '')
on conflict (id) do nothing;
insert into public.servicos (id, escola, origem, prioridade, servico, descricao, tipo, urgente, paralisado, obs)
values ('e18', 'E.E. Prof. Renato Pinheiro Conduru', 'Plano ETI 2026', 3, 'Adequação da rede hidráulica', 'Intervenções na infraestrutura hidráulica da escola.', 'Hidráulica', false, false, '')
on conflict (id) do nothing;
insert into public.servicos (id, escola, origem, prioridade, servico, descricao, tipo, urgente, paralisado, obs)
values ('e19', 'E.E. Mário Barbosa', 'Solicitação emergencial', 1, 'Manutenção da estrutura da caixa d''água', 'Caixa d''água de concreto com vazamento pelas fissuras, sem registro de quando foi construída. Risco de desabamento de toda a estrutura.', 'Estrutura', true, false, '')
on conflict (id) do nothing;
insert into public.servicos (id, escola, origem, prioridade, servico, descricao, tipo, urgente, paralisado, obs)
values ('e20', 'E.E. Mário Barbosa', 'Solicitação emergencial', 2, 'Recuperação da estrutura do telhado', 'Estrutura comprometida, com risco de tombar, em área de passagem de alunos para os banheiros. Reparo urgente.', 'Cobertura', true, false, '')
on conflict (id) do nothing;
insert into public.servicos (id, escola, origem, prioridade, servico, descricao, tipo, urgente, paralisado, obs)
values ('e21', 'E.E. Mário Barbosa', 'Solicitação emergencial', 3, 'Conservação do bloqueio do bloco sem uso', 'Conservação da estrutura de bloqueio da parte do bloco sem condições de uso (mais de 10 anos sem uso).', 'Conservação', false, false, '')
on conflict (id) do nothing;
insert into public.servicos (id, escola, origem, prioridade, servico, descricao, tipo, urgente, paralisado, obs)
values ('e22', 'E.E. Mário Barbosa', 'Solicitação emergencial', 4, 'Cobertura e manutenção da quadra de esportes', 'Execução da cobertura e manutenção da estrutura da quadra.', 'Quadra', false, false, '')
on conflict (id) do nothing;

-- 7. Inserção / Carga inicial das 144 Etapas (com cronograma até 20/12/2026)
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (1, 'e01', 1, 'Serviços preliminares', 5, 0, '2026-10-01', '2026-10-03', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (2, 'e01', 2, 'Adequação de vedações e esquadrias', 25, 0, '2026-10-04', '2026-10-17', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (3, 'e01', 3, 'Instalações elétricas (circuitos e quadro)', 30, 0, '2026-10-18', '2026-11-02', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (4, 'e01', 4, 'Suportes e drenos', 10, 0, '2026-11-03', '2026-11-08', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (5, 'e01', 5, 'Instalação dos aparelhos', 25, 0, '2026-11-09', '2026-11-21', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (6, 'e01', 6, 'Testes e limpeza', 5, 0, '2026-11-22', '2026-11-24', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (7, 'e02', 1, 'Serviços preliminares e demolições', 5, 0, '2026-10-06', '2026-10-08', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (8, 'e02', 2, 'Fundação (sapatas e blocos)', 15, 0, '2026-10-09', '2026-10-16', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (9, 'e02', 3, 'Superestrutura – pilares de apoio', 15, 0, '2026-10-17', '2026-10-24', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (10, 'e02', 4, 'Estrutura metálica da cobertura', 20, 0, '2026-10-25', '2026-11-04', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (11, 'e02', 5, 'Telhamento, calhas e rufos', 15, 0, '2026-11-05', '2026-11-13', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (12, 'e02', 6, 'Recuperação do piso da quadra', 15, 0, '2026-11-14', '2026-11-21', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (13, 'e02', 7, 'Pintura e demarcação', 10, 0, '2026-11-22', '2026-11-26', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (14, 'e02', 8, 'Limpeza final', 5, 0, '2026-11-27', '2026-11-29', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (15, 'e03', 1, 'Serviços preliminares e demolições', 10, 0, '2026-10-11', '2026-10-16', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (16, 'e03', 2, 'Recuperação estrutural e alvenaria', 20, 0, '2026-10-17', '2026-10-27', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (17, 'e03', 3, 'Cobertura e forro', 20, 0, '2026-10-28', '2026-11-07', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (18, 'e03', 4, 'Instalações elétricas e hidráulicas', 20, 0, '2026-11-08', '2026-11-18', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (19, 'e03', 5, 'Revestimentos e pisos', 15, 0, '2026-11-19', '2026-11-26', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (20, 'e03', 6, 'Pintura e esquadrias', 15, 0, '2026-11-27', '2026-12-04', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (21, 'e04', 1, 'Serviços preliminares e locação', 5, 0, '2026-10-05', '2026-10-07', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (22, 'e04', 2, 'Fundação', 15, 0, '2026-10-08', '2026-10-15', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (23, 'e04', 3, 'Superestrutura (pilares, vigas e laje)', 20, 0, '2026-10-16', '2026-10-26', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (24, 'e04', 4, 'Alvenaria', 10, 0, '2026-10-27', '2026-11-01', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (25, 'e04', 5, 'Cobertura', 15, 0, '2026-11-02', '2026-11-09', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (26, 'e04', 6, 'Instalações elétricas, hidráulicas e gás', 15, 0, '2026-11-10', '2026-11-17', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (27, 'e04', 7, 'Revestimentos e pisos', 10, 0, '2026-11-18', '2026-11-23', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (28, 'e04', 8, 'Pintura, esquadrias e limpeza', 10, 0, '2026-11-24', '2026-11-28', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (29, 'e05', 1, 'Demolições e retiradas', 10, 0, '2026-10-10', '2026-10-15', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (30, 'e05', 2, 'Instalações hidrossanitárias', 30, 0, '2026-10-16', '2026-10-31', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (31, 'e05', 3, 'Instalações elétricas', 10, 0, '2026-11-01', '2026-11-06', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (32, 'e05', 4, 'Revestimentos e pisos', 25, 0, '2026-11-07', '2026-11-19', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (33, 'e05', 5, 'Louças e metais', 15, 0, '2026-11-20', '2026-11-28', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (34, 'e05', 6, 'Pintura e limpeza', 10, 0, '2026-11-29', '2026-12-03', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (35, 'e06', 1, 'Serviços preliminares e mobilização', 5, 0, '2026-10-15', '2026-10-17', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (36, 'e06', 2, 'Fundação (sapatas e blocos)', 20, 0, '2026-10-18', '2026-10-28', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (37, 'e06', 3, 'Superestrutura – pilares de apoio', 20, 0, '2026-10-29', '2026-11-08', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (38, 'e06', 4, 'Estrutura metálica da cobertura', 25, 0, '2026-11-09', '2026-11-22', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (39, 'e06', 5, 'Telhamento, calhas e rufos', 20, 0, '2026-11-23', '2026-12-03', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (40, 'e06', 6, 'Acabamentos e limpeza final', 10, 0, '2026-12-04', '2026-12-08', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (41, 'e07', 1, 'Serviços preliminares e mobilização', 5, 0, '2026-10-09', '2026-10-11', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (42, 'e07', 2, 'Fundação (sapatas e blocos)', 20, 0, '2026-10-12', '2026-10-22', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (43, 'e07', 3, 'Superestrutura – pilares de apoio', 20, 0, '2026-10-23', '2026-11-02', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (44, 'e07', 4, 'Estrutura metálica da cobertura', 25, 0, '2026-11-03', '2026-11-16', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (45, 'e07', 5, 'Telhamento, calhas e rufos', 20, 0, '2026-11-17', '2026-11-27', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (46, 'e07', 6, 'Acabamentos e limpeza final', 10, 0, '2026-11-28', '2026-12-02', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (47, 'e08', 1, 'Serviços preliminares e limpeza', 5, 0, '2026-10-14', '2026-10-16', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (48, 'e08', 2, 'Recuperação estrutural e alvenaria', 15, 0, '2026-10-17', '2026-10-24', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (49, 'e08', 3, 'Cobertura', 15, 0, '2026-10-25', '2026-11-01', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (50, 'e08', 4, 'Forro', 20, 0, '2026-11-02', '2026-11-12', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (51, 'e08', 5, 'Instalações elétricas', 25, 0, '2026-11-13', '2026-11-26', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (52, 'e08', 6, 'Pintura e esquadrias', 15, 0, '2026-11-27', '2026-12-04', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (53, 'e08', 7, 'Limpeza final', 5, 0, '2026-12-05', '2026-12-07', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (54, 'e09', 1, 'Serviços preliminares e locação', 5, 0, '2026-10-19', '2026-10-21', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (55, 'e09', 2, 'Fundação', 15, 0, '2026-10-22', '2026-10-29', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (56, 'e09', 3, 'Superestrutura (pilares, vigas e laje)', 20, 0, '2026-10-30', '2026-11-09', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (57, 'e09', 4, 'Alvenaria', 10, 0, '2026-11-10', '2026-11-15', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (58, 'e09', 5, 'Cobertura', 15, 0, '2026-11-16', '2026-11-23', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (59, 'e09', 6, 'Instalações elétricas, hidráulicas e gás', 15, 0, '2026-11-24', '2026-12-01', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (60, 'e09', 7, 'Revestimentos e pisos', 10, 0, '2026-12-02', '2026-12-07', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (61, 'e09', 8, 'Pintura, esquadrias e limpeza', 10, 0, '2026-12-08', '2026-12-12', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (62, 'e10', 1, 'Serviços preliminares e demolições', 10, 0, '2026-10-01', '2026-10-06', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (63, 'e10', 2, 'Recuperação estrutural e alvenaria', 20, 0, '2026-10-07', '2026-10-17', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (64, 'e10', 3, 'Cobertura e forro', 15, 0, '2026-10-18', '2026-10-25', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (65, 'e10', 4, 'Instalações elétricas e hidráulicas', 20, 0, '2026-10-26', '2026-11-05', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (66, 'e10', 5, 'Revestimentos, pisos e bancadas', 15, 0, '2026-11-06', '2026-11-13', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (67, 'e10', 6, 'Pintura e esquadrias', 15, 0, '2026-11-14', '2026-11-21', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (68, 'e10', 7, 'Limpeza final', 5, 0, '2026-11-22', '2026-11-24', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (69, 'e11', 1, 'Serviços preliminares e mobilização', 5, 0, '2026-10-06', '2026-10-08', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (70, 'e11', 2, 'Fundação (sapatas e blocos)', 15, 0, '2026-10-09', '2026-10-16', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (71, 'e11', 3, 'Superestrutura – pilares de apoio', 15, 0, '2026-10-17', '2026-10-24', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (72, 'e11', 4, 'Estrutura metálica da cobertura', 20, 0, '2026-10-25', '2026-11-04', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (73, 'e11', 5, 'Telhamento, calhas e rufos', 15, 0, '2026-11-05', '2026-11-13', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (74, 'e11', 6, 'Arquibancada', 25, 0, '2026-11-14', '2026-11-26', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (75, 'e11', 7, 'Acabamentos e limpeza final', 5, 0, '2026-11-27', '2026-11-29', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (76, 'e12', 1, 'Serviços preliminares e demolições', 10, 0, '2026-10-11', '2026-10-16', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (77, 'e12', 2, 'Recuperação estrutural e alvenaria', 20, 0, '2026-10-17', '2026-10-27', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (78, 'e12', 3, 'Cobertura e forro', 20, 0, '2026-10-28', '2026-11-07', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (79, 'e12', 4, 'Instalações elétricas e hidráulicas', 20, 0, '2026-11-08', '2026-11-18', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (80, 'e12', 5, 'Revestimentos e pisos', 15, 0, '2026-11-19', '2026-11-26', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (81, 'e12', 6, 'Pintura e esquadrias', 15, 0, '2026-11-27', '2026-12-04', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (82, 'e13', 1, 'Serviços preliminares e mobilização', 5, 0, '2026-10-05', '2026-10-07', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (83, 'e13', 2, 'Fundação (sapatas e blocos)', 15, 0, '2026-10-08', '2026-10-15', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (84, 'e13', 3, 'Superestrutura – pilares de apoio', 15, 0, '2026-10-16', '2026-10-23', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (85, 'e13', 4, 'Estrutura metálica da cobertura', 15, 0, '2026-10-24', '2026-11-01', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (86, 'e13', 5, 'Telhamento, calhas e rufos', 10, 0, '2026-11-02', '2026-11-06', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (87, 'e13', 6, 'Vestiário (alvenaria, instalações e revestimentos)', 20, 0, '2026-11-07', '2026-11-17', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (88, 'e13', 7, 'Arquibancada', 15, 0, '2026-11-18', '2026-11-25', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (89, 'e13', 8, 'Acabamentos e limpeza final', 5, 0, '2026-11-26', '2026-11-28', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (90, 'e14', 1, 'Demolições e retiradas', 10, 0, '2026-10-10', '2026-10-15', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (91, 'e14', 2, 'Instalações hidrossanitárias', 30, 0, '2026-10-16', '2026-10-31', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (92, 'e14', 3, 'Instalações elétricas', 10, 0, '2026-11-01', '2026-11-06', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (93, 'e14', 4, 'Revestimentos e pisos', 25, 0, '2026-11-07', '2026-11-19', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (94, 'e14', 5, 'Louças e metais', 15, 0, '2026-11-20', '2026-11-28', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (95, 'e14', 6, 'Pintura e limpeza', 10, 0, '2026-11-29', '2026-12-03', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (96, 'e15', 1, 'Demolições e retiradas', 10, 0, '2026-10-15', '2026-10-20', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (97, 'e15', 2, 'Instalações hidráulicas e gás', 20, 0, '2026-10-21', '2026-10-31', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (98, 'e15', 3, 'Instalações elétricas', 15, 0, '2026-11-01', '2026-11-08', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (99, 'e15', 4, 'Revestimentos e pisos', 25, 0, '2026-11-09', '2026-11-22', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (100, 'e15', 5, 'Bancadas e esquadrias', 15, 0, '2026-11-23', '2026-11-30', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (101, 'e15', 6, 'Pintura e limpeza', 15, 0, '2026-12-01', '2026-12-08', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (102, 'e16', 1, 'Serviços preliminares', 5, 0, '2026-10-09', '2026-10-11', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (103, 'e16', 2, 'Fechamento das salas (alvenaria e esquadrias)', 35, 0, '2026-10-12', '2026-10-30', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (104, 'e16', 3, 'Forro', 15, 0, '2026-10-31', '2026-11-07', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (105, 'e16', 4, 'Instalações elétricas para climatização', 25, 0, '2026-11-08', '2026-11-21', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (106, 'e16', 5, 'Pintura', 15, 0, '2026-11-22', '2026-11-29', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (107, 'e16', 6, 'Limpeza final', 5, 0, '2026-11-30', '2026-12-02', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (108, 'e17', 1, 'Serviços preliminares e demolições', 10, 0, '2026-10-14', '2026-10-19', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (109, 'e17', 2, 'Recuperação estrutural e alvenaria', 20, 0, '2026-10-20', '2026-10-30', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (110, 'e17', 3, 'Cobertura e forro', 20, 0, '2026-10-31', '2026-11-10', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (111, 'e17', 4, 'Instalações elétricas e hidráulicas', 20, 0, '2026-11-11', '2026-11-21', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (112, 'e17', 5, 'Revestimentos e pisos', 15, 0, '2026-11-22', '2026-11-29', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (113, 'e17', 6, 'Pintura e esquadrias', 15, 0, '2026-11-30', '2026-12-07', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (114, 'e18', 1, 'Levantamento e serviços preliminares', 10, 0, '2026-10-19', '2026-10-24', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (115, 'e18', 2, 'Escavações e demolições', 15, 0, '2026-10-25', '2026-11-01', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (116, 'e18', 3, 'Tubulações e conexões', 35, 0, '2026-11-02', '2026-11-20', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (117, 'e18', 4, 'Reservação e registros', 15, 0, '2026-11-21', '2026-11-28', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (118, 'e18', 5, 'Testes de estanqueidade', 10, 0, '2026-11-29', '2026-12-04', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (119, 'e18', 6, 'Recomposição de pisos e revestimentos', 15, 0, '2026-12-05', '2026-12-12', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (120, 'e19', 1, 'Isolamento da área e escoramento', 10, 0, '2026-10-01', '2026-10-06', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (121, 'e19', 2, 'Inspeção e diagnóstico estrutural', 10, 0, '2026-10-07', '2026-10-11', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (122, 'e19', 3, 'Esvaziamento e limpeza do reservatório', 5, 0, '2026-10-12', '2026-10-14', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (123, 'e19', 4, 'Recuperação da fundação', 15, 0, '2026-10-15', '2026-10-22', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (124, 'e19', 5, 'Recuperação da superestrutura (pilares e vigas)', 30, 0, '2026-10-23', '2026-11-08', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (125, 'e19', 6, 'Tratamento de fissuras e impermeabilização', 20, 0, '2026-11-09', '2026-11-19', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (126, 'e19', 7, 'Teste de estanqueidade e religação', 10, 0, '2026-11-20', '2026-11-24', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (127, 'e20', 1, 'Isolamento da passagem e escoramento', 10, 0, '2026-10-06', '2026-10-11', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (128, 'e20', 2, 'Desmontagem do telhado comprometido', 15, 0, '2026-10-12', '2026-10-19', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (129, 'e20', 3, 'Recuperação dos apoios (pilares e vigas)', 20, 0, '2026-10-20', '2026-10-30', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (130, 'e20', 4, 'Nova estrutura do telhado', 30, 0, '2026-10-31', '2026-11-15', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (131, 'e20', 5, 'Telhamento, calhas e rufos', 20, 0, '2026-11-16', '2026-11-26', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (132, 'e20', 6, 'Limpeza final', 5, 0, '2026-11-27', '2026-11-29', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (133, 'e21', 1, 'Inspeção do bloco e do bloqueio', 10, 0, '2026-10-11', '2026-10-16', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (134, 'e21', 2, 'Limpeza e remoção de entulho', 15, 0, '2026-10-17', '2026-10-24', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (135, 'e21', 3, 'Recuperação do fechamento (alvenaria e portões)', 40, 0, '2026-10-25', '2026-11-15', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (136, 'e21', 4, 'Tratamento de pontos críticos', 20, 0, '2026-11-16', '2026-11-26', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (137, 'e21', 5, 'Sinalização de área interditada', 15, 0, '2026-11-27', '2026-12-04', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (138, 'e22', 1, 'Serviços preliminares e mobilização', 5, 0, '2026-10-16', '2026-10-18', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (139, 'e22', 2, 'Fundação (sapatas e blocos)', 15, 0, '2026-10-19', '2026-10-26', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (140, 'e22', 3, 'Superestrutura – pilares de apoio', 20, 0, '2026-10-27', '2026-11-06', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (141, 'e22', 4, 'Estrutura metálica da cobertura', 20, 0, '2026-11-07', '2026-11-17', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (142, 'e22', 5, 'Telhamento, calhas e rufos', 15, 0, '2026-11-18', '2026-11-25', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (143, 'e22', 6, 'Manutenção do piso e alambrado', 20, 0, '2026-11-26', '2026-12-06', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);
insert into public.etapas (id, servico_id, ordem, nome, peso, pct, inicio, fim, paralisada, justificativa)
values (144, 'e22', 7, 'Limpeza final', 5, 0, '2026-12-07', '2026-12-09', false, null)
on conflict (id) do update set
  inicio = coalesce(public.etapas.inicio, excluded.inicio),
  fim = coalesce(public.etapas.fim, excluded.fim);

-- 8. Zera percentuais e histórico (conforme solicitado)
update public.etapas set pct = 0, paralisada = false, justificativa = null, paralisada_em = null;
update public.servicos set paralisado = false, obs = '';
delete from public.medicoes;
