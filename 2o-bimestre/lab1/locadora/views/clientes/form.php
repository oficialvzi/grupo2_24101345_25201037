<h1><?= e($titulo) ?></h1>

<?php require __DIR__ . '/../layout/erros.php'; ?>

<form class="formulario" method="post" action="<?= e($acao) ?>">
    <?= csrf_field() ?>

    <label>Nome
        <input name="nome" value="<?= e($cliente['nome']) ?>" maxlength="100" required>
    </label>

    <label>CPF
        <input name="cpf" value="<?= e($cliente['cpf']) ?>" maxlength="14" required placeholder="000.000.000-00">
    </label>

    <div class="formulario__acoes">
        <button class="botao" type="submit">Salvar</button>
        <a href="<?= e(url('/clientes')) ?>">Cancelar</a>
    </div>
</form>
