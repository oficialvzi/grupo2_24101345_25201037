<?php
// Acesso à tabela Veiculo (os "carros" do roteiro).
// Todas as consultas usam prepared statements; nenhuma entrada do usuário é
// concatenada no SQL. Carros excluídos (soft delete) nunca são listados.

class CarroModel {
    private PDO $pdo;

    public function __construct() {
        $this->pdo = getConnection();
    }

    /** Lista carros ativos, opcionalmente filtrando pelo modelo ou pela placa. */
    public function listar(string $busca = ''): array {
        $stmt = $this->pdo->prepare(
            'SELECT v.id, v.placa, v.modelo, v.status, v.id_categoria,
                    c.nome AS categoria, c.valor_diaria
             FROM Veiculo v
             JOIN Categoria c ON c.id = v.id_categoria
             WHERE (v.modelo LIKE :modelo OR v.placa LIKE :placa)
               AND v.deleted_at IS NULL
             ORDER BY v.id'
        );
        $stmt->execute([
            ':modelo' => '%' . $busca . '%',
            ':placa'  => '%' . $busca . '%',
        ]);
        return $stmt->fetchAll();
    }

    public function buscarPorId(int $id): ?array {
        $stmt = $this->pdo->prepare(
            'SELECT id, placa, modelo, id_categoria, status
             FROM Veiculo
             WHERE id = :id AND deleted_at IS NULL'
        );
        $stmt->execute([':id' => $id]);
        return $stmt->fetch() ?: null;
    }

    public function criar(array $dados): int {
        $stmt = $this->pdo->prepare(
            'INSERT INTO Veiculo (placa, modelo, id_categoria, status)
             VALUES (:placa, :modelo, :id_categoria, :status)'
        );
        $stmt->execute([
            ':placa'        => $dados['placa'],
            ':modelo'       => $dados['modelo'],
            ':id_categoria' => $dados['id_categoria'],
            ':status'       => $dados['status'],
        ]);
        return (int) $this->pdo->lastInsertId();
    }

    public function atualizar(int $id, array $dados): void {
        $stmt = $this->pdo->prepare(
            'UPDATE Veiculo
             SET placa = :placa, modelo = :modelo,
                 id_categoria = :id_categoria, status = :status
             WHERE id = :id AND deleted_at IS NULL'
        );
        $stmt->execute([
            ':placa'        => $dados['placa'],
            ':modelo'       => $dados['modelo'],
            ':id_categoria' => $dados['id_categoria'],
            ':status'       => $dados['status'],
            ':id'           => $id,
        ]);
    }

    /** Soft delete (Etapa 3): o registro continua no banco com deleted_at preenchido. */
    public function excluir(int $id): bool {
        $stmt = $this->pdo->prepare(
            'UPDATE Veiculo SET deleted_at = NOW() WHERE id = :id AND deleted_at IS NULL'
        );
        $stmt->execute([':id' => $id]);
        return $stmt->rowCount() > 0;
    }
}
