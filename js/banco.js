/* =========================================================
   LIGAÇÃO COM O SUPABASE (usada pelo painel e pelo login)

   Aqui ficam só o endereço do projeto e a chave PÚBLICA.
   Essa chave foi feita para ficar no site: sozinha ela não abre
   nada, quem protege os dados são as trancas (RLS) do banco.sql.

   COMO CONFIGURAR:
   1. Crie um projeto em https://supabase.com (gratuito).
   2. Em Project Settings > API, copie a "Project URL" e a chave
      "anon public" (ou "publishable", nos projetos novos).
   3. Cole os dois valores abaixo, no lugar de "COLE_AQUI...".
   4. No SQL Editor do projeto, cole o conteúdo de banco.sql e
      rode. Troque o e-mail dentro da função e_a_dona() pelo
      e-mail que você vai usar para entrar no painel.
   5. Em Authentication > Providers, deixe "Email" habilitado.
   6. Crie seu usuário em Authentication > Users > Add user
      (com o mesmo e-mail usado em e_a_dona()).

   NUNCA coloque aqui a chave secreta (service_role ou sb_secret).

   Toda página que usa o banco precisa carregar, nesta ordem:
   1. https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2
   2. este arquivo
   ========================================================= */
window.SUPABASE_URL = "COLE_AQUI_A_URL_DO_SEU_PROJETO_SUPABASE";
window.SUPABASE_CHAVE = "COLE_AQUI_A_CHAVE_PUBLICA_ANON_DO_SUPABASE";

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
