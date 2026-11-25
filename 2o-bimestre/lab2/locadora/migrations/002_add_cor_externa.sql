-- 002_add_cor_externa.sql
-- Expandir: cria a coluna nova ao lado da antiga (Veiculo.cor continua existindo).
-- Nasce NULL para não quebrar o código atual, que ainda não conhece cor_externa
-- e faz INSERT em Veiculo sem informá-la.
-- up
ALTER TABLE Veiculo ADD COLUMN cor_externa VARCHAR(30) NULL;

-- down
ALTER TABLE Veiculo DROP COLUMN cor_externa;
