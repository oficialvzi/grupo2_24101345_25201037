<div class="cabecalho">
    <h1>Carros</h1>
    <a class="botao" href="<?= e(url('/carros/novo')) ?>">+ Novo carro</a>
</div>

<form class="busca" method="get" action="<?= e(url('/carros')) ?>">
    <input type="search" name="busca" value="<?= e($busca) ?>" placeholder="Buscar por modelo ou placa">
    <button class="botao botao--secundario" type="submit">Buscar</button>
    <?php if ($busca !== ''): ?>
        <a href="<?= e(url('/carros')) ?>">Limpar</a>
    <?php endif; ?>
</form>

<?php if ($busca !== ''): ?>
    <p class="info">Resultado para <strong><?= e($busca) ?></strong>: <?= count($carros) ?> carro(s).</p>
<?php endif; ?>

<table class="tabela">
    <thead>
        <tr><th>ID</th><th>Placa</th><th>Modelo</th><th>Categoria</th><th>Diária</th><th>Status</th><th></th></tr>
    </thead>
    <tbody>
    <?php foreach ($carros as $carro): ?>
        <tr>
            <td><?= e($carro['id']) ?></td>
            <td><code><?= e($carro['placa']) ?></code></td>
            <td><?= e($carro['modelo']) ?></td>
            <td><?= e($carro['categoria']) ?></td>
            <td>R$ <?= e(number_format((float) $carro['valor_diaria'], 2, ',', '.')) ?></td>
            <td><span class="selo selo--<?= e($carro['status']) ?>"><?= e($carro['status']) ?></span></td>
            <td class="acoes">
                <a href="<?= e(url('/carros/editar', ['id' => $carro['id']])) ?>">Editar</a>
                <?php if (usuario_logado()['perfil'] === 'admin'): ?>
                <form method="post" action="<?= e(url('/carros/excluir')) ?>" data-confirmar="Excluir o carro <?= e($carro['placa']) ?>?">
                    <?= csrf_field() ?>
                    <input type="hidden" name="id" value="<?= e($carro['id']) ?>">
                    <button class="link-perigo" type="submit">Excluir</button>
                </form>
                <?php endif; ?>
            </td>
        </tr>
    <?php endforeach; ?>
    <?php if (!$carros): ?>
        <tr><td colspan="7" class="vazio">Nenhum carro encontrado.</td></tr>
    <?php endif; ?>
    </tbody>
</table>
