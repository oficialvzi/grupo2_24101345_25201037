<?php
// Acesso à tabela Cliente (Etapa 2 — frontend + backend).

class ClienteModel {
    private PDO $pdo;

    public function __construct() {
        $this->pdo = getConnection();
    }

    /** Lista clientes com o total de locações de cada um. */
    public function listar(string $busca = ''): array {
        $stmt = $this->pdo->prepare(
            'SELECT c.id, c.nome, c.cpf, COUNT(l.id) AS total_locacoes
             FROM Cliente c
             LEFT JOIN Locacao l ON l.id_cliente = c.id
             WHERE c.nome LIKE :nome OR c.cpf LIKE :cpf
             GROUP BY c.id, c.nome, c.cpf
             ORDER BY c.nome'
        );
        $stmt->execute([
            ':nome' => '%' . $busca . '%',
            ':cpf'  => '%' . $busca . '%',
        ]);
        return $stmt->fetchAll();
    }

    public function buscarPorId(int $id): ?array {
        $stmt = $this->pdo->prepare('SELECT id, nome, cpf FROM Cliente WHERE id = :id');
        $stmt->execute([':id' => $id]);
        return $stmt->fetch() ?: null;
    }

    public function criar(array $dados): int {
        $stmt = $this->pdo->prepare('INSERT INTO Cliente (nome, cpf) VALUES (:nome, :cpf)');
        $stmt->execute([':nome' => $dados['nome'], ':cpf' => $dados['cpf']]);
        return (int) $this->pdo->lastInsertId();
    }

    public function atualizar(int $id, array $dados): void {
        $stmt = $this->pdo->prepare('UPDATE Cliente SET nome = :nome, cpf = :cpf WHERE id = :id');
        $stmt->execute([':nome' => $dados['nome'], ':cpf' => $dados['cpf'], ':id' => $id]);
    }

    /** Exclusão física; o MySQL recusa (erro 1451) se o cliente tiver locações. */
    public function excluir(int $id): bool {
        $stmt = $this->pdo->prepare('DELETE FROM Cliente WHERE id = :id');
        $stmt->execute([':id' => $id]);
        return $stmt->rowCount() > 0;
    }
}
