-- =============================================================================
-- Locadora v2 · Parte 02 · Etapa 0 — ajustes de esquema ANTES da Etapa 1
--
-- O roteiro supõe clientes(cidade) e carros(cor). No nosso esquema do Bimestre I
-- essas colunas não existiam (lacunas do modelo). Elas são criadas aqui, na
-- preparação, para que:
--   * a Etapa 1 (expandir/contrair) tenha uma coluna "cor" real para virar "cor_externa";
--   * o ETL da Etapa 3 tenha "cidade" para a dim_cliente e o painel 4.
--
-- Roda UMA vez, antes de gerar_carga.sql e antes da migration 001_baseline:
-- o baseline da Etapa 1 já representa o esquema com estas colunas.
--
--   mysql -u admin_locadora -p --default-character-set=utf8mb4 locadora_lab < scripts/preparar_esquema.sql
-- =============================================================================

-- 1. Novas colunas (NULL, para não quebrar nenhum INSERT existente)
ALTER TABLE Cliente ADD COLUMN cidade VARCHAR(50) NULL AFTER cpf;
ALTER TABLE Veiculo ADD COLUMN cor    VARCHAR(30) NULL AFTER modelo;

-- 2. Dados dos registros originais do Bimestre I
UPDATE Cliente SET cidade = CASE id
    WHEN 1 THEN 'Brasília'
    WHEN 2 THEN 'Goiânia'
    WHEN 3 THEN 'São Paulo'
    WHEN 4 THEN 'Belo Horizonte'
    WHEN 5 THEN 'Rio de Janeiro'
END
WHERE id BETWEEN 1 AND 5;

-- Inclui o veículo excluído (soft delete, id 5): o backfill da Etapa 1 também
-- precisa migrar a cor dele.
UPDATE Veiculo SET cor = CASE id
    WHEN 1 THEN 'Preto'
    WHEN 2 THEN 'Branco'
    WHEN 3 THEN 'Prata'
    WHEN 4 THEN 'Vermelho'
    WHEN 5 THEN 'Cinza'
END
WHERE id BETWEEN 1 AND 5;

-- 3. Conferência
SELECT id, nome, cpf, cidade FROM Cliente ORDER BY id;
SELECT id, placa, modelo, cor, deleted_at FROM Veiculo ORDER BY id;
