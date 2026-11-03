-- =====================================================================
--  BANCO DE DADOS DO PAINEL DA FOUND
--  Onde colar: Supabase > seu projeto > SQL Editor > New query.
--  Cole o arquivo inteiro e clique em "Run".
--  Pode rodar de novo sem medo: nada é apagado e nada é duplicado.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1) QUEM É A DONA
-- Uma função pequena que responde "sim" só quando quem está logada
-- é você (pelo seu e-mail). Todas as trancas abaixo usam ela.
-- Troque o e-mail abaixo pelo e-mail que você usa para entrar no painel.
-- ---------------------------------------------------------------------
create or replace function public.e_a_dona()
returns boolean
language sql
stable
set search_path = ''
as $$
  select coalesce(auth.jwt() ->> 'email', '') = 'contato@foundmarketing.com.br';
$$;


-- ---------------------------------------------------------------------
-- 2) AS TABELAS
-- ---------------------------------------------------------------------

-- CLIENTES: a base de leads, conversas e clientes ativos da agência.
create table if not exists public.clientes (
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

-- CALENDÁRIO: agenda de reuniões, gravações, postagens e prazos.
create table if not exists public.calendario (
  id         uuid primary key default gen_random_uuid(),
  cliente_id uuid references public.clientes(id) on delete set null,
  titulo     text not null,
  tipo       text not null default 'reuniao' check (tipo in ('gravar','editar','postar','reuniao','prazo')),
  data       date not null,
  feito      boolean not null default false,
  nota       text,
  criado_em  timestamptz not null default now()
);

-- PROJETOS: os trabalhos fechados com cada cliente, do briefing à entrega.
create table if not exists public.projetos (
  id         uuid primary key default gen_random_uuid(),
  cliente_id uuid references public.clientes(id) on delete set null,
  titulo     text not null,
  tipo       text,
  status     text not null default 'Briefing' check (status in ('Briefing','Diagnóstico','Estratégia','Produção','Revisão','Aprovado','Entregue')),
  prazo      date,
  valor      numeric,
  favorito   boolean not null default false,
  nota       text,
  criado_em  timestamptz not null default now()
);

-- TAREFAS: a lista de afazeres do dia a dia.
create table if not exists public.tarefas (
  id        uuid primary key default gen_random_uuid(),
  titulo    text not null,
  feita     boolean not null default false,
  data      date,
  criado_em timestamptz not null default now()
);

-- CHECKLIST: passos de processos internos (ex.: onboarding de cliente,
-- entrega mensal), organizados por categoria.
create table if not exists public.checklist_itens (
  id         uuid primary key default gen_random_uuid(),
  categoria  text not null,
  titulo     text not null,
  descricao  text,
  feito      boolean not null default false,
  ordem      int not null default 0,
  criado_em  timestamptz not null default now()
);


-- ---------------------------------------------------------------------
-- 3) AS TRANCAS (RLS) — só a dona lê e escreve, ninguém mais
-- ---------------------------------------------------------------------
alter table public.clientes        enable row level security;
alter table public.calendario      enable row level security;
alter table public.projetos        enable row level security;
alter table public.tarefas         enable row level security;
alter table public.checklist_itens enable row level security;

drop policy if exists "dona_tudo_clientes" on public.clientes;
create policy "dona_tudo_clientes" on public.clientes for all using (public.e_a_dona()) with check (public.e_a_dona());

drop policy if exists "dona_tudo_calendario" on public.calendario;
create policy "dona_tudo_calendario" on public.calendario for all using (public.e_a_dona()) with check (public.e_a_dona());

drop policy if exists "dona_tudo_projetos" on public.projetos;
create policy "dona_tudo_projetos" on public.projetos for all using (public.e_a_dona()) with check (public.e_a_dona());

drop policy if exists "dona_tudo_tarefas" on public.tarefas;
create policy "dona_tudo_tarefas" on public.tarefas for all using (public.e_a_dona()) with check (public.e_a_dona());

drop policy if exists "dona_tudo_checklist" on public.checklist_itens;
create policy "dona_tudo_checklist" on public.checklist_itens for all using (public.e_a_dona()) with check (public.e_a_dona());


-- ---------------------------------------------------------------------
-- 4) CHECKLIST DE EXEMPLO (só aparece se a tabela estiver vazia)
-- Serve pra você ver o painel funcionando. Pode editar ou apagar.
-- ---------------------------------------------------------------------
insert into public.checklist_itens (categoria, titulo, descricao, ordem)
select * from (values
  ('Novo cliente', 'EXEMPLO · Assinar contrato e enviar boas-vindas', 'Contrato assinado, acesso ao grupo/canal de comunicação enviado.', 1),
  ('Novo cliente', 'EXEMPLO · Reunião de diagnóstico', 'Entender posicionamento atual, concorrência e objetivos do cliente.', 2),
  ('Novo cliente', 'EXEMPLO · Análise de perfil e redes', 'Auditoria de bio, destaques, feed e histórico de conteúdo.', 3),
  ('Planejamento mensal', 'EXEMPLO · Calendário de conteúdo do mês', 'Montar o calendário com temas, formatos e datas de postagem.', 1),
  ('Planejamento mensal', 'EXEMPLO · Aprovação do cliente', 'Enviar o planejamento para aprovação antes de produzir.', 2),
  ('Entrega mensal', 'EXEMPLO · Relatório de resultados', 'Números do mês: alcance, seguidores, engajamento, leads gerados.', 1),
  ('Entrega mensal', 'EXEMPLO · Reunião de alinhamento', 'Apresentar resultados e próximos passos para o mês seguinte.', 2)
) as v(categoria, titulo, descricao, ordem)
where not exists (select 1 from public.checklist_itens);
