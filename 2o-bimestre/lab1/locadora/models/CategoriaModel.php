<?php
// Categorias alimentam o <select> do formulário de carros.

class CategoriaModel {
    private PDO $pdo;

    public function __construct() {
        $this->pdo = getConnection();
    }

    public function listar(): array {
        $stmt = $this->pdo->prepare('SELECT id, nome, valor_diaria FROM Categoria ORDER BY nome');
        $stmt->execute();
        return $stmt->fetchAll();
    }

    public function existe(int $id): bool {
        $stmt = $this->pdo->prepare('SELECT 1 FROM Categoria WHERE id = :id');
        $stmt->execute([':id' => $id]);
        return (bool) $stmt->fetchColumn();
    }
}
