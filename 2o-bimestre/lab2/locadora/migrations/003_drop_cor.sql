-- 003_drop_cor.sql
-- Contrair: apaga a coluna antiga. Só foi aplicada depois que o código parou
-- de ler e de gravar em "cor" (ver CarroModel).
-- ATENÇÃO: o down recria a coluna VAZIA. Os dados apagados pelo up só voltam
-- com backup (Parte 01, Etapa 3).
-- up
ALTER TABLE Veiculo DROP COLUMN cor;

-- down
ALTER TABLE Veiculo ADD COLUMN cor VARCHAR(30) NULL;
