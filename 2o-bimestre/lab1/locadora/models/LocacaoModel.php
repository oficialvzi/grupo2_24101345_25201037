<?php
// Locações. Os triggers do Bimestre I mudam o status do veículo sozinhos:
// INSERT -> 'locado'; data_real preenchida -> 'disponivel'.

class LocacaoModel {
    private PDO $pdo;

    public function __construct() {
        $this->pdo = getConnection();
    }

    public function listar(): array {
        $stmt = $this->pdo->prepare(
            'SELECT l.id, c.nome AS cliente, v.modelo, v.placa,
                    fr.nome AS filial_retirada, fd.nome AS filial_devolucao,
                    l.data_retirada, l.data_prevista, l.data_real, l.valor_total, l.status
             FROM Locacao l
             JOIN Cliente c  ON c.id  = l.id_cliente
             JOIN Veiculo v  ON v.id  = l.id_veiculo
             JOIN Filial  fr ON fr.id = l.id_filial_retirada
             JOIN Filial  fd ON fd.id = l.id_filial_devolucao
             ORDER BY l.data_real IS NULL DESC, l.data_retirada DESC, l.id DESC'
        );
        $stmt->execute();
        return $stmt->fetchAll();
    }

    public function buscarPorId(int $id): ?array {
        $stmt = $this->pdo->prepare(
            'SELECT id, id_veiculo, data_retirada, data_real, status FROM Locacao WHERE id = :id'
        );
        $stmt->execute([':id' => $id]);
        return $stmt->fetch() ?: null;
    }

    /** Veículos que podem ser locados agora (disponíveis e não excluídos). */
    public function veiculosDisponiveis(): array {
        $stmt = $this->pdo->prepare(
            'SELECT v.id, v.placa, v.modelo, c.valor_diaria
             FROM Veiculo v
             JOIN Categoria c ON c.id = v.id_categoria
             WHERE v.status = :status AND v.deleted_at IS NULL
             ORDER BY v.modelo, v.placa'
        );
        $stmt->execute([':status' => 'disponivel']);
        return $stmt->fetchAll();
    }

    /**
     * Abre a locação numa transação: trava a linha do veículo (FOR UPDATE)
     * para que duas locações simultâneas não peguem o mesmo carro.
     * Retorna null se o veículo não estiver mais disponível.
     */
    public function criar(array $d): ?int {
        $this->pdo->beginTransaction();
        try {
            $stmt = $this->pdo->prepare(
                'SELECT c.valor_diaria
                 FROM Veiculo v
                 JOIN Categoria c ON c.id = v.id_categoria
                 WHERE v.id = :id AND v.status = :status AND v.deleted_at IS NULL
                 FOR UPDATE'
            );
            $stmt->execute([':id' => $d['id_veiculo'], ':status' => 'disponivel']);
            $diaria = $stmt->fetchColumn();

            if ($diaria === false) {
                $this->pdo->rollBack();
                return null;
            }

            $dias  = max(1, (int) (new DateTime($d['data_retirada']))->diff(new DateTime($d['data_prevista']))->days);
            $stmt = $this->pdo->prepare(
                'INSERT INTO Locacao (id_cliente, id_veiculo, id_filial_retirada, id_filial_devolucao,
                                      data_retirada, data_prevista, valor_total, status)
                 VALUES (:cliente, :veiculo, :retirada, :devolucao, :data_retirada, :data_prevista, :valor, :status)'
            );
            $stmt->execute([
                ':cliente'       => $d['id_cliente'],
                ':veiculo'       => $d['id_veiculo'],
                ':retirada'      => $d['id_filial_retirada'],
                ':devolucao'     => $d['id_filial_devolucao'],
                ':data_retirada' => $d['data_retirada'],
                ':data_prevista' => $d['data_prevista'],
                ':valor'         => $dias * (float) $diaria,
                ':status'        => 'ativa',
            ]);
            $id = (int) $this->pdo->lastInsertId();
            $this->pdo->commit();
            return $id;
        } catch (Throwable $e) {
            if ($this->pdo->inTransaction()) {
                $this->pdo->rollBack();
            }
            throw $e;
        }
    }

    public function registrarDevolucao(int $id, string $dataReal): void {
        $stmt = $this->pdo->prepare(
            'UPDATE Locacao SET data_real = :data_real, status = :status
             WHERE id = :id AND data_real IS NULL'
        );
        $stmt->execute([':data_real' => $dataReal, ':status' => 'finalizada', ':id' => $id]);
    }
}
