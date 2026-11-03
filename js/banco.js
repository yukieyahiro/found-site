/* =========================================================
   LIGAÇÃO COM O SUPABASE (usada pelo painel e pelo login)

   Aqui ficam só o endereço do projeto e a chave PÚBLICA.
   Essa chave foi feita para ficar no site: sozinha ela não abre
   nada, quem protege os dados são as trancas (RLS) do banco.sql.

   Este painel usa o MESMO projeto Supabase do painel da Yukie
   (yukieyahiro's Project), só que com tabelas próprias, todas com
   o prefixo "found_", para não colidir com as tabelas do outro
   painel. O login também é o mesmo: ayyahiro@gmail.com.

   FALTA VOCÊ FAZER:
   No SQL Editor desse projeto Supabase, cole o conteúdo de
   banco.sql (deste repositório) e rode. Ele só cria as tabelas
   "found_*" e as trancas (RLS) delas — não mexe em nada que já
   existe do painel da Yukie.

   NUNCA coloque aqui a chave secreta (service_role ou sb_secret).

   Toda página que usa o banco precisa carregar, nesta ordem:
   1. https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2
   2. este arquivo
   ========================================================= */
window.SUPABASE_URL = "https://odgidcbqjvbmobrdvmej.supabase.co";
window.SUPABASE_CHAVE = "sb_publishable_VGWxgK5rir_XGXUK-nvk2g_KEiVSLNL";

/* window.banco é o "atalho" que as páginas usam para falar com o Supabase.
   Se a biblioteca do Supabase não carregar, ou as credenciais acima não
   tiverem sido preenchidas, ele fica vazio e cada página avisa a dona. */
window.banco = null;
try {
  var configurado = window.SUPABASE_URL && window.SUPABASE_URL.indexOf("COLE_AQUI") === -1 &&
                     window.SUPABASE_CHAVE && window.SUPABASE_CHAVE.indexOf("COLE_AQUI") === -1;
  if (configurado && window.supabase && typeof window.supabase.createClient === "function") {
    window.banco = window.supabase.createClient(window.SUPABASE_URL, window.SUPABASE_CHAVE);
  }
} catch (e) {
  window.banco = null;
}
