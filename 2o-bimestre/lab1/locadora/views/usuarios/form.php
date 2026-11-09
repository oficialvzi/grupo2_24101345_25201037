<h1><?= e($titulo) ?></h1>

<?php require __DIR__ . '/../layout/erros.php'; ?>

<form class="formulario" method="post" action="<?= e(url('/usuarios/salvar')) ?>">
    <?= csrf_field() ?>
    <label>Nome
        <input name="nome" value="<?= e($usuario['nome']) ?>" maxlength="100" required>
    </label>
    <label>E-mail
        <input type="email" name="email" value="<?= e($usuario['email']) ?>" maxlength="150" required>
    </label>
    <label>Senha (mínimo 8 caracteres)
        <input type="password" name="senha" minlength="8" required>
    </label>
    <label>Confirmar senha
        <input type="password" name="senha_confirmacao" minlength="8" required>
    </label>
    <label>Perfil
        <select name="perfil">
            <?php foreach ($perfis as $p): ?>
                <option value="<?= e($p) ?>" <?= $usuario['perfil'] === $p ? 'selected' : '' ?>><?= e($p) ?></option>
            <?php endforeach; ?>
        </select>
    </label>
    <div class="formulario__acoes">
        <button class="botao" type="submit">Salvar</button>
        <a href="<?= e(url('/usuarios')) ?>">Cancelar</a>
    </div>
</form>
