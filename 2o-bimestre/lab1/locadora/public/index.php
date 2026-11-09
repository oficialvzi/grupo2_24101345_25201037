<?php
// =============================================================================
// Front controller — única porta de entrada da aplicação.
// Só a pasta public/ fica exposta; config/, models/, controllers/, views/ e
// logs/ ficam fora do alcance do navegador.
// =============================================================================

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../core/helpers.php';

ini_set('display_errors', APP_DEBUG ? '1' : '0');

spl_autoload_register(function (string $classe): void {
    foreach (['controllers', 'models'] as $pasta) {
        $arquivo = __DIR__ . "/../$pasta/$classe.php";
        if (is_file($arquivo)) {
            require_once $arquivo;
            return;
        }
    }
});

session_start([
    'cookie_httponly' => true,
    'cookie_samesite' => 'Lax',
]);

// Cabeçalhos de segurança básicos (Etapa 4).
header_remove('X-Powered-By');
header('X-Content-Type-Options: nosniff');
header('X-Frame-Options: DENY');
header("Content-Security-Policy: default-src 'self'; script-src 'self'; style-src 'self'");

// Rotas: "MÉTODO /caminho" => [Controller, método, acesso]
// acesso: 'publico' (sem login), 'login' (qualquer usuário logado) ou 'admin'.
$rotas = [
    'GET /login'              => [AuthController::class, 'formulario', 'publico'],
    'POST /login'             => [AuthController::class, 'entrar', 'publico'],
    'POST /logout'            => [AuthController::class, 'sair', 'login'],

    'GET /carros'             => [CarroController::class, 'index', 'login'],
    'GET /carros/novo'        => [CarroController::class, 'criar', 'login'],
    'POST /carros/salvar'     => [CarroController::class, 'salvar', 'login'],
    'GET /carros/editar'      => [CarroController::class, 'editar', 'login'],
    'POST /carros/atualizar'  => [CarroController::class, 'atualizar', 'login'],
    'POST /carros/excluir'    => [CarroController::class, 'excluir', 'admin'],

    'GET /clientes'            => [ClienteController::class, 'index', 'login'],
    'GET /clientes/novo'       => [ClienteController::class, 'criar', 'login'],
    'POST /clientes/salvar'    => [ClienteController::class, 'salvar', 'login'],
    'GET /clientes/editar'     => [ClienteController::class, 'editar', 'login'],
    'POST /clientes/atualizar' => [ClienteController::class, 'atualizar', 'login'],
    'POST /clientes/excluir'   => [ClienteController::class, 'excluir', 'admin'],

    'GET /locacoes'           => [LocacaoController::class, 'index', 'login'],
    'GET /locacoes/nova'      => [LocacaoController::class, 'criar', 'login'],
    'POST /locacoes/salvar'   => [LocacaoController::class, 'salvar', 'login'],
    'POST /locacoes/devolver' => [LocacaoController::class, 'devolver', 'login'],

    'GET /usuarios'           => [UsuarioController::class, 'index', 'admin'],
    'GET /usuarios/novo'      => [UsuarioController::class, 'criar', 'admin'],
    'POST /usuarios/salvar'   => [UsuarioController::class, 'salvar', 'admin'],
];

$caminho = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';
if (BASE_URL !== '' && str_starts_with($caminho, BASE_URL)) {
    $caminho = substr($caminho, strlen(BASE_URL)) ?: '/';
}
$caminho = rtrim($caminho, '/') ?: '/';

if ($caminho === '/') {
    redirect('/carros');
}

$metodoHttp = $_SERVER['REQUEST_METHOD'] ?? 'GET';
$chave = ($metodoHttp === 'HEAD' ? 'GET' : $metodoHttp) . ' ' . $caminho;

if (!isset($rotas[$chave])) {
    http_response_code(404);
    view('erros/404', ['titulo' => 'Página não encontrada']);
    exit;
}

[$controller, $metodo, $acesso] = $rotas[$chave];
if ($acesso === 'login') exigirLogin();
if ($acesso === 'admin') exigirPerfil('admin');

try {
    (new $controller())->$metodo();
} catch (Throwable $e) {
    // Detalhe técnico vai para logs/erros.log; o usuário vê só a mensagem genérica.
    registrar_erro($e);
    http_response_code(500);
    view('erros/500', ['titulo' => 'Erro']);
}
