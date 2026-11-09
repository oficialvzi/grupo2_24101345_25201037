<?php
// Usuários do SISTEMA (tabela usuarios), que não são os usuários do SGBD.

class UsuarioModel {
    private PDO $pdo;

    public function __construct() {
        $this->pdo = getConnection();
    }

    public function buscarPorEmail(string $email): ?array {
        $stmt = $this->pdo->prepare(
            'SELECT id, nome, email, senha_hash, perfil FROM usuarios WHERE email = :email'
        );
        $stmt->execute([':email' => $email]);
        return $stmt->fetch() ?: null;
    }

    public function listar(): array {
        $stmt = $this->pdo->prepare('SELECT id, nome, email, perfil, criado_em FROM usuarios ORDER BY nome');
        $stmt->execute();
        return $stmt->fetchAll();
    }

    /** A senha chega em texto puro e é gravada só como hash. */
    public function criar(string $nome, string $email, string $senha, string $perfil): int {
        $stmt = $this->pdo->prepare(
            'INSERT INTO usuarios (nome, email, senha_hash, perfil) VALUES (:nome, :email, :hash, :perfil)'
        );
        $stmt->execute([
            ':nome'   => $nome,
            ':email'  => $email,
            ':hash'   => password_hash($senha, PASSWORD_DEFAULT),
            ':perfil' => $perfil,
        ]);
        return (int) $this->pdo->lastInsertId();
    }
}
