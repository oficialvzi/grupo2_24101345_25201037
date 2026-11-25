<?php
// Funções utilitárias usadas por controllers e views.

/** Escapa qualquer valor antes de exibir em HTML (proteção contra XSS — Etapa 4). */
function e($valor): string {
    return htmlspecialchars((string) $valor, ENT_QUOTES, 'UTF-8');
}

/** Monta uma URL da aplicação respeitando o BASE_URL. */
function url(string $caminho, array $query = []): string {
    $url = BASE_URL . $caminho;
    return $query ? $url . '?' . http_build_query($query) : $url;
}

function redirect(string $caminho, array $query = []): never {
    header('Location: ' . url($caminho, $query));
    exit;
}

/** Renderiza uma view dentro do layout. As views só recebem dados prontos. */
function view(string $nome, array $dados = []): void {
    extract($dados);
    $flash = flash();
    require __DIR__ . '/../views/layout/header.php';
    require __DIR__ . '/../views/' . $nome . '.php';
    require __DIR__ . '/../views/layout/footer.php';
}

/** Guarda (com argumentos) ou consome (sem argumentos) a mensagem de sucesso/erro. */
function flash(?string $tipo = null, ?string $mensagem = null): ?array {
    if ($tipo !== null) {
        $_SESSION['flash'] = ['tipo' => $tipo, 'mensagem' => $mensagem];
        return null;
    }
    $f = $_SESSION['flash'] ?? null;
    unset($_SESSION['flash']);
    return $f;
}

/** Dados do último formulário enviado, para repreencher após erro de validação. */
function old(string $campo, $padrao = '') {
    return $_SESSION['old'][$campo] ?? $padrao;
}

// ---- CSRF (Etapa 4): todo POST precisa carregar o token da sessão ----------

function csrf_token(): string {
    if (empty($_SESSION['csrf'])) {
        $_SESSION['csrf'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['csrf'];
}

function csrf_field(): string {
    return '<input type="hidden" name="_csrf" value="' . e(csrf_token()) . '">';
}

function csrf_verificar(): void {
    $enviado = $_POST['_csrf'] ?? '';
    if (!is_string($enviado) || !hash_equals(csrf_token(), $enviado)) {
        http_response_code(419);
        exit('Requisição inválida (token CSRF ausente ou incorreto).');
    }
}

/** Lê um campo de texto do POST já sem espaços nas pontas. */
function input(string $campo): string {
    $v = $_POST[$campo] ?? '';
    return is_string($v) ? trim($v) : '';
}

// ---- Erros e log (Etapa 6) ---------------------------------------------------

/** Grava o detalhe técnico no log. O usuário só vê a mensagem genérica. */
function registrar_erro(Throwable $e): void {
    $linha = '[' . date('c') . '] ' . get_class($e) . ': ' . $e->getMessage()
           . ' em ' . basename($e->getFile()) . ':' . $e->getLine() . PHP_EOL;
    error_log($linha, 3, LOG_ERROS);
}

// ---- Autenticação (Etapa 6) --------------------------------------------------

function usuario_logado(): ?array {
    if (empty($_SESSION['usuario_id'])) {
        return null;
    }
    return [
        'id'     => $_SESSION['usuario_id'],
        'nome'   => $_SESSION['usuario_nome'] ?? '',
        'perfil' => $_SESSION['perfil'] ?? 'atendente',
    ];
}

function exigirLogin(): void {
    if (empty($_SESSION['usuario_id'])) {
        flash('erro', 'Faça login para continuar.');
        redirect('/login');
    }
}

function exigirPerfil(string $perfil): void {
    exigirLogin();
    if (($_SESSION['perfil'] ?? '') !== $perfil) {
        flash('erro', 'Seu perfil não tem permissão para esta ação.');
        redirect('/carros');
    }
}
