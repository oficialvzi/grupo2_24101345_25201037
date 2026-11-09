<div class="cabecalho">
    <h1>Usuários do sistema</h1>
    <a class="botao" href="<?= e(url('/usuarios/novo')) ?>">+ Novo usuário</a>
</div>

<table class="tabela">
    <thead>
        <tr><th>ID</th><th>Nome</th><th>E-mail</th><th>Perfil</th><th>Criado em</th></tr>
    </thead>
    <tbody>
    <?php foreach ($usuarios as $u): ?>
        <tr>
            <td><?= e($u['id']) ?></td>
            <td><?= e($u['nome']) ?></td>
            <td><?= e($u['email']) ?></td>
            <td><span class="selo selo--<?= e($u['perfil']) ?>"><?= e($u['perfil']) ?></span></td>
            <td><?= e(date('d/m/Y H:i', strtotime($u['criado_em']))) ?></td>
        </tr>
    <?php endforeach; ?>
    </tbody>
</table>
