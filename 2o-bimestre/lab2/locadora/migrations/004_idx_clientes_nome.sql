-- 004_idx_clientes_nome.sql
-- Índice para busca por prefixo em Cliente.nome (LIKE 'Cliente teste 123%').
-- LIKE com '%' no início não usa índice: por isso a Q3 foi reescrita como prefixo.
-- up
CREATE INDEX idx_cliente_nome ON Cliente (nome);

-- down
DROP INDEX idx_cliente_nome ON Cliente;
