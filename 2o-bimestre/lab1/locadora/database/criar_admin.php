<?php
// Cria os usuários iniciais do sistema (seed). Senhas guardadas com password_hash.
// Uso: php database/criar_admin.php
require_once __DIR__ . '/../config/database.php';

$usuarios = [
    ['Administrador', 'admin@locadora.local',     'Admin@2026', 'admin'],
    ['Atendente',     'atendente@locadora.local', 'Atend@2026', 'atendente'],
];

$pdo  = getConnection();
$stmt = $pdo->prepare(
    'INSERT INTO usuarios (nome, email, senha_hash, perfil)
     VALUES (:nome, :email, :hash, :perfil)
     ON DUPLICATE KEY UPDATE nome = VALUES(nome), senha_hash = VALUES(senha_hash), perfil = VALUES(perfil)'
);
foreach ($usuarios as [$nome, $email, $senha, $perfil]) {
    $stmt->execute([
        ':nome'   => $nome,
        ':email'  => $email,
        ':hash'   => password_hash($senha, PASSWORD_DEFAULT),
        ':perfil' => $perfil,
    ]);
    echo "Usuário {$email} ({$perfil}) pronto.\n";
}
