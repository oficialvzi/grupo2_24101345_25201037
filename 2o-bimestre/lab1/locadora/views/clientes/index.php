<div class="cabecalho">
    <h1>Clientes</h1>
    <a class="botao" href="<?= e(url('/clientes/novo')) ?>">+ Novo cliente</a>
</div>

<form class="busca" method="get" action="<?= e(url('/clientes')) ?>">
    <input type="search" name="busca" value="<?= e($busca) ?>" placeholder="Buscar por nome ou CPF">
    <button class="botao botao--secundario" type="submit">Buscar</button>
    <?php if ($busca !== ''): ?>
        <a href="<?= e(url('/clientes')) ?>">Limpar</a>
    <?php endif; ?>
</form>

<table class="tabela">
    <thead>
        <tr><th>ID</th><th>Nome</th><th>CPF</th><th>Locações</th><th></th></tr>
    </thead>
    <tbody>
    <?php foreach ($clientes as $cliente): ?>
        <tr>
            <td><?= e($cliente['id']) ?></td>
            <td><?= e($cliente['nome']) ?></td>
            <td><code><?= e($cliente['cpf']) ?></code></td>
            <td><?= e($cliente['total_locacoes']) ?></td>
            <td class="acoes">
                <a href="<?= e(url('/clientes/editar', ['id' => $cliente['id']])) ?>">Editar</a>
                <?php if (usuario_logado()['perfil'] === 'admin'): ?>
                <form method="post" action="<?= e(url('/clientes/excluir')) ?>" data-confirmar="Excluir o cliente <?= e($cliente['nome']) ?>?">
                    <?= csrf_field() ?>
                    <input type="hidden" name="id" value="<?= e($cliente['id']) ?>">
                    <button class="link-perigo" type="submit">Excluir</button>
                </form>
                <?php endif; ?>
            </td>
        </tr>
    <?php endforeach; ?>
    <?php if (!$clientes): ?>
        <tr><td colspan="5" class="vazio">Nenhum cliente encontrado.</td></tr>
    <?php endif; ?>
    </tbody>
</table>
