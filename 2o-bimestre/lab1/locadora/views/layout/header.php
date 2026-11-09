<!doctype html>
<html lang="pt-BR">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><?= e($titulo ?? APP_NOME) ?> · <?= e(APP_NOME) ?></title>
    <link rel="stylesheet" href="<?= e(url('/css/style.css')) ?>">
    <script src="<?= e(url('/js/app.js')) ?>" defer></script>
</head>
<body>
<header class="topo">
    <div class="container topo__conteudo">
        <a class="marca" href="<?= e(url('/carros')) ?>"><?= e(APP_NOME) ?></a>
        <?php if ($usuarioLogado = usuario_logado()): ?>
        <nav>
            <a href="<?= e(url('/carros')) ?>">Carros</a>
            <a href="<?= e(url('/clientes')) ?>">Clientes</a>
            <a href="<?= e(url('/locacoes')) ?>">Locações</a>
            <?php if ($usuarioLogado['perfil'] === 'admin'): ?>
                <a href="<?= e(url('/usuarios')) ?>">Usuários</a>
            <?php endif; ?>
            <span class="usuario"><?= e($usuarioLogado['nome']) ?> (<?= e($usuarioLogado['perfil']) ?>)</span>
            <form class="sair" method="post" action="<?= e(url('/logout')) ?>">
                <?= csrf_field() ?>
                <button type="submit">Sair</button>
            </form>
        </nav>
        <?php endif; ?>
    </div>
</header>
<main class="container">
<?php if ($flash): ?>
    <div class="alerta alerta--<?= e($flash['tipo']) ?>"><?= e($flash['mensagem']) ?></div>
<?php endif; ?>
