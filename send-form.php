<?php
// Recebe o form de contato do index.html (fetch em JSON) e envia por e-mail pra Found.
// Hospede este arquivo na mesma pasta do index.html no HostGator (suporta PHP nativamente).

header("Content-Type: application/json; charset=utf-8");

$destino = "contato@foundmarketing.com.br";

function erro($msg, $codigo = 400) {
    http_response_code($codigo);
    echo json_encode(["ok" => false, "erro" => $msg]);
    exit;
}

if ($_SERVER["REQUEST_METHOD"] !== "POST") {
    erro("Método não permitido", 405);
}

$dados = json_decode(file_get_contents("php://input"), true);
if (!$dados) {
    erro("Dados inválidos");
}

$nome = trim($dados["nome"] ?? "");
$email = trim($dados["email"] ?? "");
$mensagem = trim($dados["mensagem"] ?? "");

if ($nome === "" || $email === "" || $mensagem === "") {
    erro("Preencha todos os campos");
}
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    erro("E-mail inválido");
}

// Remove quebras de linha de nome/e-mail pra evitar header injection.
$nome = str_replace(["\r", "\n"], " ", $nome);
$email = str_replace(["\r", "\n"], " ", $email);

$assunto = "Novo contato pelo site - $nome";
$corpo = "Nome: $nome\nE-mail: $email\n\nMensagem:\n$mensagem\n";

$headers = "From: Site Found <$destino>\r\n";
$headers .= "Reply-To: $nome <$email>\r\n";
$headers .= "Content-Type: text/plain; charset=utf-8\r\n";

$enviado = mail($destino, $assunto, $corpo, $headers);

if (!$enviado) {
    erro("Falha ao enviar, tenta de novo em um instante", 500);
}

echo json_encode(["ok" => true]);
