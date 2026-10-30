-- =============================================================
-- PORTAL DOS PASTORES – MARANATA
-- Tabelas com prefixo pastores_ para conviver com outros apps no mesmo projeto
-- Rode este arquivo inteiro no Supabase: SQL Editor > New query > Run
-- =============================================================

-- 1) QUEM PODE ENTRAR -----------------------------------------
-- 'pastor' = a conta compartilhada (só a senha na tela inicial)
-- 'admin'  = os três administradores (e-mail + senha próprios)
create table if not exists public.pastores_acessos (
  email text primary key,
  papel text not null check (papel in ('pastor','admin')),
  nome  text
);
alter table public.pastores_acessos enable row level security;

create or replace function public.pastores_papel()
returns text language sql stable security definer set search_path = public as $$
  select papel from public.pastores_acessos
  where lower(email) = lower(coalesce(auth.jwt() ->> 'email',''))
$$;

create or replace function public.pastores_e_membro() returns boolean
language sql stable as $$ select public.pastores_papel() in ('pastor','admin') $$;

create or replace function public.pastores_e_admin() returns boolean
language sql stable as $$ select public.pastores_papel() = 'admin' $$;

drop policy if exists "ver proprio acesso" on public.pastores_acessos;
create policy "ver proprio acesso" on public.pastores_acessos
  for select to authenticated
  using (lower(email) = lower(auth.jwt() ->> 'email') or public.pastores_e_admin());

-- 2) TABELAS DO PORTAL ----------------------------------------
create table if not exists public.pastores_atas (
  id uuid primary key default gen_random_uuid(),
  titulo text not null,
  data_reuniao date,
  descricao text,
  arquivo_path text not null,
  arquivo_nome text,
  texto text,            -- texto extraído do PDF/Word, usado na busca
  criado_em timestamptz not null default now()
);
alter table public.pastores_atas add column if not exists texto text;

create table if not exists public.pastores_escalas (
  id uuid primary key default gen_random_uuid(),
  titulo text not null,
  referencia text not null,   -- mês no formato AAAA-MM
  resumo jsonb,               -- resumo lido automaticamente do PDF
  arquivo_path text not null,
  arquivo_nome text,
  criado_em timestamptz not null default now()
);

create table if not exists public.pastores_manual (
  id uuid primary key default gen_random_uuid(),
  titulo text not null default 'Manual do Membro',
  observacao text,
  arquivo_path text not null,
  arquivo_nome text,
  criado_em timestamptz not null default now()
);

create table if not exists public.pastores_informes (
  id uuid primary key default gen_random_uuid(),
  titulo text not null,
  conteudo text,
  arquivo_path text,
  arquivo_nome text,
  criado_em timestamptz not null default now()
);

create table if not exists public.pastores_aniversariantes (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  dia smallint not null check (dia between 1 and 31),
  mes smallint not null check (mes between 1 and 12),
  observacao text,
  criado_em timestamptz not null default now()
);

create table if not exists public.pastores_agenda (
  id uuid primary key default gen_random_uuid(),
  titulo text not null,
  data_inicio date not null,
  data_fim date,
  horario text,
  local text,
  descricao text,
  criado_em timestamptz not null default now()
);

create table if not exists public.pastores_logos (
  id uuid primary key default gen_random_uuid(),
  titulo text not null,
  instituicao text,
  arquivo_path text not null,
  arquivo_nome text,
  criado_em timestamptz not null default now()
);

-- 3) REGRAS: membros leem, só admins escrevem -----------------
do $$
declare t text;
begin
  foreach t in array array['pastores_atas','pastores_escalas','pastores_manual','pastores_informes','pastores_aniversariantes','pastores_agenda','pastores_logos'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists "membros leem" on public.%I', t);
    execute format('drop policy if exists "admins escrevem" on public.%I', t);
    execute format('create policy "membros leem" on public.%I for select to authenticated using (public.pastores_e_membro())', t);
    execute format('create policy "admins escrevem" on public.%I for all to authenticated using (public.pastores_e_admin()) with check (public.pastores_e_admin())', t);
  end loop;
end $$;

-- 4) ARQUIVOS (bucket privado) --------------------------------
insert into storage.buckets (id, name, public)
values ('pastores', 'pastores', false)
on conflict (id) do nothing;

drop policy if exists "pastores membros leem"   on storage.objects;
drop policy if exists "pastores admins enviam"  on storage.objects;
drop policy if exists "pastores admins alteram" on storage.objects;
drop policy if exists "pastores admins apagam"  on storage.objects;

create policy "pastores membros leem" on storage.objects
  for select to authenticated using (bucket_id = 'pastores' and public.pastores_e_membro());
create policy "pastores admins enviam" on storage.objects
  for insert to authenticated with check (bucket_id = 'pastores' and public.pastores_e_admin());
create policy "pastores admins alteram" on storage.objects
  for update to authenticated using (bucket_id = 'pastores' and public.pastores_e_admin());
create policy "pastores admins apagam" on storage.objects
  for delete to authenticated using (bucket_id = 'pastores' and public.pastores_e_admin());

-- 5) CADASTRE OS ACESSOS --------------------------------------
-- Troque os e-mails abaixo pelos reais. O e-mail da conta compartilhada
-- precisa ser o MESMO que está em CONTA_PASTORES no index.html.
insert into public.pastores_acessos (email, papel, nome) values
  ('pastores@portalmaranata.app', 'pastor', 'Acesso compartilhado'),
  ('edmilson.moraes@live.com', 'admin', 'Edmilson'),
  ('rafaelblume@gmail.com', 'admin', 'Rafael'),
  ('chicodepaula@gmail.com', 'admin', 'Chico de Paula')
on conflict (email) do update set papel = excluded.papel, nome = excluded.nome;

-- 6) AJUSTES DE SEGURANÇA -------------------------------------
alter function public.pastores_e_membro() set search_path = public;
alter function public.pastores_e_admin() set search_path = public;
revoke execute on function public.pastores_papel() from public, anon;
grant execute on function public.pastores_papel() to authenticated;
