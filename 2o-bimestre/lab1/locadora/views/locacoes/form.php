<h1><?= e($titulo) ?></h1>

<?php require __DIR__ . '/../layout/erros.php'; ?>

<form class="formulario" method="post" action="<?= e(url('/locacoes/salvar')) ?>">
    <?= csrf_field() ?>
    <label>Cliente
        <select name="id_cliente" required>
            <option value="">Selecione…</option>
            <?php foreach ($clientes as $c): ?>
                <option value="<?= e($c['id']) ?>" <?= (int) $locacao['id_cliente'] === (int) $c['id'] ? 'selected' : '' ?>><?= e($c['nome']) ?> — <?= e($c['cpf']) ?></option>
            <?php endforeach; ?>
        </select>
    </label>
    <label>Veículo disponível
        <select name="id_veiculo" required>
            <option value="">Selecione…</option>
            <?php foreach ($veiculos as $v): ?>
                <option value="<?= e($v['id']) ?>" <?= (int) $locacao['id_veiculo'] === (int) $v['id'] ? 'selected' : '' ?>><?= e($v['modelo']) ?> (<?= e($v['placa']) ?>) — R$ <?= e(number_format((float) $v['valor_diaria'], 2, ',', '.')) ?>/dia</option>
            <?php endforeach; ?>
        </select>
    </label>
    <label>Filial de retirada
        <select name="id_filial_retirada" required>
            <option value="">Selecione…</option>
            <?php foreach ($filiais as $f): ?>
                <option value="<?= e($f['id']) ?>" <?= (int) $locacao['id_filial_retirada'] === (int) $f['id'] ? 'selected' : '' ?>><?= e($f['nome']) ?> — <?= e($f['cidade']) ?></option>
            <?php endforeach; ?>
        </select>
    </label>
    <label>Filial de devolução
        <select name="id_filial_devolucao" required>
            <option value="">Selecione…</option>
            <?php foreach ($filiais as $f): ?>
                <option value="<?= e($f['id']) ?>" <?= (int) $locacao['id_filial_devolucao'] === (int) $f['id'] ? 'selected' : '' ?>><?= e($f['nome']) ?> — <?= e($f['cidade']) ?></option>
            <?php endforeach; ?>
        </select>
    </label>
    <label>Data de retirada
        <input type="date" name="data_retirada" value="<?= e($locacao['data_retirada']) ?>" required>
    </label>
    <label>Data prevista de devolução
        <input type="date" name="data_prevista" value="<?= e($locacao['data_prevista']) ?>" required>
    </label>
    <div class="formulario__acoes">
        <button class="botao" type="submit">Abrir locação</button>
        <a href="<?= e(url('/locacoes')) ?>">Cancelar</a>
    </div>
</form>
