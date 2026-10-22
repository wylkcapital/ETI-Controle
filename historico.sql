-- Rode uma vez no Supabase › SQL Editor.
-- Cada "Salvar medição" grava uma linha aqui: o % do serviço naquele momento e o que mudou.
create table if not exists public.medicoes (
  id bigserial primary key,
  servico_id text not null references public.servicos(id) on delete cascade,
  pct numeric not null,
  detalhes jsonb not null default '[]',
  usuario text,
  em timestamptz not null default now()
);
create index if not exists medicoes_servico_em on public.medicoes (servico_id, em);

alter table public.medicoes enable row level security;
create policy "medicoes leitura publica" on public.medicoes for select using (true);
create policy "medicoes insert logado" on public.medicoes for insert to authenticated with check (true);

alter publication supabase_realtime add table public.medicoes;
