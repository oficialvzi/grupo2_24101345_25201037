<div class="cabecalho">
    <h1>Locações</h1>
    <a class="botao" href="<?= e(url('/locacoes/nova')) ?>">+ Nova locação</a>
</div>

<table class="tabela">
    <thead>
        <tr><th>#</th><th>Cliente</th><th>Veículo</th><th>Retirada</th><th>Prevista</th><th>Devolução</th><th>Valor</th><th>Status</th></tr>
    </thead>
    <tbody>
    <?php foreach ($locacoes as $l): ?>
        <tr>
            <td><?= e($l['id']) ?></td>
            <td><?= e($l['cliente']) ?></td>
            <td><?= e($l['modelo']) ?> <code><?= e($l['placa']) ?></code></td>
            <td><?= e(date('d/m/Y', strtotime($l['data_retirada']))) ?><br><small><?= e($l['filial_retirada']) ?></small></td>
            <td><?= e(date('d/m/Y', strtotime($l['data_prevista']))) ?><br><small><?= e($l['filial_devolucao']) ?></small></td>
            <td>
                <?php if ($l['data_real'] !== null): ?>
                    <?= e(date('d/m/Y', strtotime($l['data_real']))) ?>
                <?php else: ?>
                    <form class="devolucao" method="post" action="<?= e(url('/locacoes/devolver')) ?>">
                        <?= csrf_field() ?>
                        <input type="hidden" name="id" value="<?= e($l['id']) ?>">
                        <input type="date" name="data_real" value="<?= e(date('Y-m-d')) ?>" required>
                        <button class="botao botao--secundario" type="submit">Devolver</button>
                    </form>
                <?php endif; ?>
            </td>
            <td>R$ <?= e(number_format((float) $l['valor_total'], 2, ',', '.')) ?></td>
            <td><span class="selo selo--<?= e($l['status']) ?>"><?= e($l['status']) ?></span></td>
        </tr>
    <?php endforeach; ?>
    </tbody>
</table>
