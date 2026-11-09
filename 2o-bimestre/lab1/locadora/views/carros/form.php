<h1><?= e($titulo) ?></h1>

<?php require __DIR__ . '/../layout/erros.php'; ?>

<form class="formulario" method="post" action="<?= e($acao) ?>">
    <?= csrf_field() ?>

    <label>Placa
        <input name="placa" value="<?= e($carro['placa']) ?>" maxlength="10" required placeholder="ABC1D23">
    </label>

    <label>Modelo
        <input name="modelo" value="<?= e($carro['modelo']) ?>" maxlength="50" required>
    </label>

    <label>Categoria
        <select name="id_categoria" required>
            <option value="">Selecione…</option>
            <?php foreach ($categorias as $cat): ?>
                <option value="<?= e($cat['id']) ?>" <?= (int) $carro['id_categoria'] === (int) $cat['id'] ? 'selected' : '' ?>>
                    <?= e($cat['nome']) ?> — R$ <?= e(number_format((float) $cat['valor_diaria'], 2, ',', '.')) ?>/dia
                </option>
            <?php endforeach; ?>
        </select>
    </label>

    <label>Status
        <select name="status">
            <?php foreach ($statusList as $s): ?>
                <option value="<?= e($s) ?>" <?= $carro['status'] === $s ? 'selected' : '' ?>><?= e($s) ?></option>
            <?php endforeach; ?>
        </select>
    </label>

    <div class="formulario__acoes">
        <button class="botao" type="submit">Salvar</button>
        <a href="<?= e(url('/carros')) ?>">Cancelar</a>
    </div>
</form>
