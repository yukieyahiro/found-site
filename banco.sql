-- =====================================================================
--  BANCO DE DADOS DO PAINEL DA FOUND
--  Onde colar: Supabase > projeto "yukieyahiro's Project" > SQL Editor > New query.
--  Cole o arquivo inteiro e clique em "Run".
--  Pode rodar de novo sem medo: nada é apagado e nada é duplicado.
--
--  Este é o MESMO projeto Supabase usado pelo painel da Yukie (UGC).
--  Por isso todas as tabelas daqui usam o prefixo "found_": assim elas
--  não colidem com as tabelas "tarefas", "calendario" etc. que já existem
--  nesse projeto para o outro painel. A função e_a_dona() também já
--  existe (criada pelo banco.sql do painel da Yukie) — o "create or
--  replace" abaixo só garante que ela continua igual, não apaga nada.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1) QUEM É A DONA
-- Mesma função, mesma dona, dos dois painéis: só quem está logada com
-- este e-mail lê e escreve.
-- ---------------------------------------------------------------------
create or replace function public.e_a_dona()
returns boolean
language sql
stable
set search_path = ''
as $$
  select coalesce(auth.jwt() ->> 'email', '') = 'ayyahiro@gmail.com';
$$;


-- ---------------------------------------------------------------------
-- 2) AS TABELAS DA FOUND (prefixo found_)
-- ---------------------------------------------------------------------

-- FOUND_CLIENTES: a base de leads, conversas e clientes ativos da agência.
create table if not exists public.found_clientes (
  id           uuid primary key default gen_random_uuid(),
  nome         text not null,
  instagram    text,
  whatsapp     text,
  email        text,
  situacao     text not null default 'lead' check (situacao in ('lead','conversando','proposta','cliente','pausado')),
  servico      text,
  valor_mensal numeric,
  origem       text,
  nota         text,
  criado_em    timestamptz not null default now()
);

-- FOUND_CALENDARIO: agenda de reuniões, gravações, postagens e prazos.
create table if not exists public.found_calendario (
  id         uuid primary key default gen_random_uuid(),
  cliente_id uuid references public.found_clientes(id) on delete set null,
  titulo     text not null,
  tipo       text not null default 'reuniao' check (tipo in ('gravar','editar','postar','reuniao','prazo')),
  data       date not null,
  feito      boolean not null default false,
  nota       text,
  criado_em  timestamptz not null default now()
);

-- FOUND_PROJETOS: os trabalhos fechados com cada cliente, do briefing à entrega.
create table if not exists public.found_projetos (
  id         uuid primary key default gen_random_uuid(),
  cliente_id uuid references public.found_clientes(id) on delete set null,
  titulo     text not null,
  tipo       text,
  status     text not null default 'Briefing' check (status in ('Briefing','Diagnóstico','Estratégia','Produção','Revisão','Aprovado','Entregue')),
  prazo      date,
  valor      numeric,
  favorito   boolean not null default false,
  nota       text,
  criado_em  timestamptz not null default now()
);

-- FOUND_TAREFAS: a lista de afazeres do dia a dia da agência.
create table if not exists public.found_tarefas (
  id        uuid primary key default gen_random_uuid(),
  titulo    text not null,
  feita     boolean not null default false,
  data      date,
  criado_em timestamptz not null default now()
);

-- FOUND_CHECKLIST_ITENS: passos de processos internos (ex.: onboarding de
-- cliente, entrega mensal), organizados por categoria.
create table if not exists public.found_checklist_itens (
  id         uuid primary key default gen_random_uuid(),
  categoria  text not null,
  titulo     text not null,
  descricao  text,
  feito      boolean not null default false,
  ordem      int not null default 0,
  criado_em  timestamptz not null default now()
);

-- FOUND_VISITAS: uma linha por visita ao site da Found, pro Dashboard.
-- Guarda só a data, a página e de onde a pessoa veio. Nada pessoal.
create table if not exists public.found_visitas (
  id      uuid primary key default gen_random_uuid(),
  data    timestamptz not null default now(),
  pagina  text,
  origem  text
);
create index if not exists found_visitas_data_idx on public.found_visitas (data desc);

-- FOUND_IDEIAS: quadro de ideias de conteúdo, da ideia até o post.
-- Pode (ou não) estar vinculada a um cliente.
create table if not exists public.found_ideias (
  id         uuid primary key default gen_random_uuid(),
  cliente_id uuid references public.found_clientes(id) on delete set null,
  titulo     text not null,
  formato    text,
  gancho     text,
  status     text not null default 'ideia' check (status in ('ideia','roteiro','produzido','postado')),
  obs        text,
  criado_em  timestamptz not null default now()
);

-- FOUND_RADAR: novidades de marketing que valem guardar (tendência,
-- formato novo, plataforma, oportunidade, caso de sucesso de outra marca).
create table if not exists public.found_radar (
  id         uuid primary key default gen_random_uuid(),
  titulo     text not null,
  categoria  text not null default 'Tendência'
             check (categoria in ('Tendência', 'Plataforma', 'Oportunidade', 'Caso de sucesso', 'Outro')),
  link       text,
  nota       text,
  status     text not null default 'nova'
             check (status in ('nova', 'testar', 'usei', 'arquivada')),
  fixada     boolean not null default false,
  criado_em  timestamptz not null default now()
);

-- FOUND_LINKS: os links e ferramentas de trabalho da agência.
create table if not exists public.found_links (
  id         uuid primary key default gen_random_uuid(),
  titulo     text not null,
  url        text not null,
  categoria  text not null default 'Ferramentas',
  descricao  text,
  favorito   boolean not null default false,
  criado_em  timestamptz not null default now()
);


-- ---------------------------------------------------------------------
-- 3) AS TRANCAS (RLS) — só a dona lê e escreve, ninguém mais
-- ---------------------------------------------------------------------
alter table public.found_clientes        enable row level security;
alter table public.found_calendario      enable row level security;
alter table public.found_projetos        enable row level security;
alter table public.found_tarefas         enable row level security;
alter table public.found_checklist_itens enable row level security;
alter table public.found_visitas         enable row level security;
alter table public.found_ideias          enable row level security;
alter table public.found_radar           enable row level security;
alter table public.found_links           enable row level security;

drop policy if exists "dona_tudo_found_clientes" on public.found_clientes;
create policy "dona_tudo_found_clientes" on public.found_clientes for all using (public.e_a_dona()) with check (public.e_a_dona());

drop policy if exists "dona_tudo_found_calendario" on public.found_calendario;
create policy "dona_tudo_found_calendario" on public.found_calendario for all using (public.e_a_dona()) with check (public.e_a_dona());

drop policy if exists "dona_tudo_found_projetos" on public.found_projetos;
create policy "dona_tudo_found_projetos" on public.found_projetos for all using (public.e_a_dona()) with check (public.e_a_dona());

drop policy if exists "dona_tudo_found_tarefas" on public.found_tarefas;
create policy "dona_tudo_found_tarefas" on public.found_tarefas for all using (public.e_a_dona()) with check (public.e_a_dona());

drop policy if exists "dona_tudo_found_checklist" on public.found_checklist_itens;
create policy "dona_tudo_found_checklist" on public.found_checklist_itens for all using (public.e_a_dona()) with check (public.e_a_dona());

drop policy if exists "dona_tudo_found_visitas" on public.found_visitas;
create policy "dona_tudo_found_visitas" on public.found_visitas for all to authenticated using (public.e_a_dona()) with check (public.e_a_dona());

drop policy if exists "dona_tudo_found_ideias" on public.found_ideias;
create policy "dona_tudo_found_ideias" on public.found_ideias for all using (public.e_a_dona()) with check (public.e_a_dona());

drop policy if exists "dona_tudo_found_radar" on public.found_radar;
create policy "dona_tudo_found_radar" on public.found_radar for all using (public.e_a_dona()) with check (public.e_a_dona());

drop policy if exists "dona_tudo_found_links" on public.found_links;
create policy "dona_tudo_found_links" on public.found_links for all using (public.e_a_dona()) with check (public.e_a_dona());


-- ---------------------------------------------------------------------
-- EXCEÇÃO: O SITE DA FOUND PODE REGISTRAR UMA VISITA
-- Qualquer pessoa pode INSERIR uma visita (pra contar no Dashboard).
-- Ler, só a dona.
-- ---------------------------------------------------------------------
drop policy if exists "site registra visita found" on public.found_visitas;
create policy "site registra visita found" on public.found_visitas
  for insert to anon, authenticated
  with check (
    char_length(coalesce(pagina, '')) <= 200
    and char_length(coalesce(origem, '')) <= 120
  );

revoke all on public.found_visitas from anon;
grant insert on public.found_visitas to anon;
grant select, insert, update, delete on public.found_visitas to authenticated;


-- ---------------------------------------------------------------------
-- 4) CHECKLIST DE EXEMPLO (só aparece se a tabela estiver vazia)
-- Serve pra você ver o painel funcionando. Pode editar ou apagar.
-- ---------------------------------------------------------------------
insert into public.found_checklist_itens (categoria, titulo, descricao, ordem)
select * from (values
  ('Novo cliente', 'EXEMPLO · Assinar contrato e enviar boas-vindas', 'Contrato assinado, acesso ao grupo/canal de comunicação enviado.', 1),
  ('Novo cliente', 'EXEMPLO · Reunião de diagnóstico', 'Entender posicionamento atual, concorrência e objetivos do cliente.', 2),
  ('Novo cliente', 'EXEMPLO · Análise de perfil e redes', 'Auditoria de bio, destaques, feed e histórico de conteúdo.', 3),
  ('Planejamento mensal', 'EXEMPLO · Calendário de conteúdo do mês', 'Montar o calendário com temas, formatos e datas de postagem.', 1),
  ('Planejamento mensal', 'EXEMPLO · Aprovação do cliente', 'Enviar o planejamento para aprovação antes de produzir.', 2),
  ('Entrega mensal', 'EXEMPLO · Relatório de resultados', 'Números do mês: alcance, seguidores, engajamento, leads gerados.', 1),
  ('Entrega mensal', 'EXEMPLO · Reunião de alinhamento', 'Apresentar resultados e próximos passos para o mês seguinte.', 2)
) as v(categoria, titulo, descricao, ordem)
where not exists (select 1 from public.found_checklist_itens);
