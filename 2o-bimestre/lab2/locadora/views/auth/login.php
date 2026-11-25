<div class="login">
    <h1>Entrar</h1>

    <?php require __DIR__ . '/../layout/erros.php'; ?>

    <form class="formulario" method="post" action="<?= e(url('/login')) ?>">
        <?= csrf_field() ?>
        <label>E-mail
            <input type="email" name="email" value="<?= e($email) ?>" required autofocus>
        </label>
        <label>Senha
            <input type="password" name="senha" required>
        </label>
        <div class="formulario__acoes">
            <button class="botao" type="submit">Entrar</button>
        </div>
    </form>
</div>
