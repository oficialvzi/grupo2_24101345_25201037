-- 005_idx_locacao_cliente_data.sql
-- Índice composto para "locações de um cliente em um período" (Q4).
-- Cobre também o índice simples de id_cliente (a coluna da esquerda).
-- up
CREATE INDEX idx_loc_cliente_data ON Locacao (id_cliente, data_retirada);

-- down
DROP INDEX idx_loc_cliente_data ON Locacao;
