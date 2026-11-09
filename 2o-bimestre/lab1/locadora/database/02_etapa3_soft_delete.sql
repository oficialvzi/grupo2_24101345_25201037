-- =============================================================================
-- Locadora v2 · Etapa 3 (Parte A) — soft delete em Veiculo ("carros")
--   mysql -u root locadora < database/02_etapa3_soft_delete.sql
--
-- "Excluir" um carro passa a ser: UPDATE Veiculo SET deleted_at = NOW() ...
-- O registro continua no banco (histórico de locações preservado) e todas as
-- listagens filtram deleted_at IS NULL.
-- =============================================================================

USE locadora;

ALTER TABLE Veiculo ADD COLUMN deleted_at DATETIME NULL DEFAULT NULL;

-- A view do Bimestre I também não pode mostrar carros excluídos.
CREATE OR REPLACE VIEW vw_veiculos_disponiveis AS
SELECT v.id             AS id_veiculo,
       v.modelo         AS modelo,
       v.placa          AS placa,
       cat.nome         AS categoria,
       cat.valor_diaria AS valor_diaria
FROM Veiculo v
JOIN Categoria cat ON v.id_categoria = cat.id
WHERE v.status = 'disponivel'
  AND v.deleted_at IS NULL;
