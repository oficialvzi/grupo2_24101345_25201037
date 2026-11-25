-- =============================================================================
-- Locadora v2 · Parte 02 · Etapa 0 — carga de volume para os testes de EXPLAIN
--
-- NÃO é migration: são dados de teste, não mudança de esquema. Nunca roda em
-- produção. Executar UMA ÚNICA VEZ, em locadora_lab, com o usuário administrativo,
-- DEPOIS de scripts/preparar_esquema.sql (que cria Cliente.cidade e Veiculo.cor):
--
--   mysql -u admin_locadora -p --default-character-set=utf8mb4 locadora_lab < scripts/gerar_carga.sql
--
-- Adaptado ao esquema real do grupo (nomes do Bimestre I):
--   clientes -> Cliente(id, nome, cpf, cidade)          -- cidade: preparar_esquema.sql
--   carros   -> Veiculo(id, placa, modelo, cor, ..., deleted_at)
--   locacoes -> Locacao(id, id_cliente, id_veiculo, id_filial_retirada,
--                       id_filial_devolucao, data_retirada, data_prevista,
--                       data_real, valor_total, status)
--   status: 'cancelada' (~2%), 'ativa' (~25%, data_real NULL), 'finalizada' (~73%)
--
-- Gera:
--   * 10.000 clientes "Cliente teste <n>", com CPF único de 11 dígitos no mesmo
--     formato do sistema (000.000.000-00): n = 4242 -> '000.000.042-42';
--   * clientes distribuídos em 6 cidades;
--   * 200.000 locações usando clientes, veículos e filiais existentes (as FKs
--     são respeitadas porque os ids vêm de SELECT nas próprias tabelas);
--   * retirada entre 2023-01-01 e 2025-12-30, devolução de 1 a 7 dias depois;
--   * valor_total entre 100 e 499.
--
-- Os "sorteios" usam CRC32 do número da linha: o resultado é reprodutível e
-- não depende de RAND(), que o otimizador pode reavaliar em tabelas derivadas.
--
-- Revisado: não há DROP, DELETE nem TRUNCATE de tabelas do sistema. As únicas
-- tabelas criadas são TEMPORARY e somem ao fim da sessão.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Clientes de teste (10.000)
-- -----------------------------------------------------------------------------
INSERT INTO Cliente (nome, cpf, cidade)
WITH dig AS (
    SELECT 0 AS d UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
    UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9
),
nums AS (
    SELECT 1 + a.d + 10 * b.d + 100 * c.d + 1000 * e.d AS n
    FROM dig a CROSS JOIN dig b CROSS JOIN dig c CROSS JOIN dig e
)
SELECT CONCAT('Cliente teste ', n),
       CONCAT(SUBSTRING(d11, 1, 3), '.', SUBSTRING(d11, 4, 3), '.',
              SUBSTRING(d11, 7, 3), '-', SUBSTRING(d11, 10, 2)),
       ELT(1 + CRC32(CONCAT('cid', n)) % 6,
           'Brasília', 'Goiânia', 'São Paulo', 'Rio de Janeiro', 'Belo Horizonte', 'Salvador')
FROM (SELECT n, LPAD(n, 11, '0') AS d11 FROM nums) t
ORDER BY n;

-- -----------------------------------------------------------------------------
-- 2. Tabelas auxiliares com os ids existentes numerados 0..N-1
--    (não supõe ids contíguos nem valor do AUTO_INCREMENT)
-- -----------------------------------------------------------------------------
CREATE TEMPORARY TABLE tmp_cli (rn INT PRIMARY KEY, id INT NOT NULL)
SELECT ROW_NUMBER() OVER (ORDER BY id) - 1 AS rn, id FROM Cliente;

-- Todos os veículos, inclusive os excluídos (soft delete): o histórico de
-- locações de um carro excluído continua existindo e o ETL precisa lidar com isso.
CREATE TEMPORARY TABLE tmp_vei (rn INT PRIMARY KEY, id INT NOT NULL)
SELECT ROW_NUMBER() OVER (ORDER BY id) - 1 AS rn, id FROM Veiculo;

-- Duas cópias de Filial: o MySQL não abre a mesma tabela TEMPORARY duas vezes
-- na mesma consulta (retirada e devolução).
CREATE TEMPORARY TABLE tmp_fil_ret (rn INT PRIMARY KEY, id INT NOT NULL)
SELECT ROW_NUMBER() OVER (ORDER BY id) - 1 AS rn, id FROM Filial;
CREATE TEMPORARY TABLE tmp_fil_dev (rn INT PRIMARY KEY, id INT NOT NULL)
SELECT rn, id FROM tmp_fil_ret;

-- O trigger trg_locacao_insert marca o veículo como 'locado' a cada INSERT.
-- Guardamos o status atual para restaurá-lo no fim e manter o sistema usável.
CREATE TEMPORARY TABLE tmp_status_veiculo (id INT PRIMARY KEY, status VARCHAR(20) NOT NULL)
SELECT id, status FROM Veiculo;

SET @qtd_cli = (SELECT COUNT(*) FROM tmp_cli);
SET @qtd_vei = (SELECT COUNT(*) FROM tmp_vei);
SET @qtd_fil = (SELECT COUNT(*) FROM tmp_fil_ret);

-- -----------------------------------------------------------------------------
-- 3. Locações (200.000), em um único INSERT ... SELECT
-- -----------------------------------------------------------------------------
INSERT INTO Locacao (id_cliente, id_veiculo, id_filial_retirada, id_filial_devolucao,
                     data_retirada, data_prevista, data_real, valor_total, status)
WITH dig AS (
    SELECT 0 AS d UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
    UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9
),
nums AS (
    SELECT a.d + 10 * b.d + 100 * c.d + 1000 * e.d + 10000 * f.d + 100000 * g.d AS n
    FROM dig a CROSS JOIN dig b CROSS JOIN dig c CROSS JOIN dig e
         CROSS JOIN dig f CROSS JOIN (SELECT 0 AS d UNION ALL SELECT 1) g
),
sorteio AS (
    SELECT n,
           CRC32(CONCAT('cli', n)) % @qtd_cli             AS rn_cli,
           CRC32(CONCAT('vei', n)) % @qtd_vei             AS rn_vei,
           CRC32(CONCAT('fre', n)) % @qtd_fil             AS rn_fre,
           CRC32(CONCAT('fde', n)) % @qtd_fil             AS rn_fde,
           DATE('2023-01-01')
             + INTERVAL (CRC32(CONCAT('dat', n)) % 1095) DAY AS dt_ret,   -- até 2025-12-30
           1 + CRC32(CONCAT('dia', n)) % 7                AS dias,       -- 1 a 7
           100 + CRC32(CONCAT('val', n)) % 400            AS valor,      -- 100 a 499
           CRC32(CONCAT('sta', n)) % 100                  AS p_status    -- 0 a 99
    FROM nums
)
SELECT c.id,
       v.id,
       fr.id,
       fd.id,
       s.dt_ret,
       s.dt_ret + INTERVAL s.dias DAY,
       CASE WHEN s.p_status BETWEEN 2 AND 26 THEN NULL               -- aberta
            ELSE s.dt_ret + INTERVAL s.dias DAY END,
       s.valor,
       CASE WHEN s.p_status < 2  THEN 'cancelada'                    -- ~2%
            WHEN s.p_status < 27 THEN 'ativa'                        -- ~25%
            ELSE 'finalizada' END                                    -- ~73%
FROM sorteio s
JOIN tmp_cli c  ON c.rn  = s.rn_cli
JOIN tmp_vei v  ON v.rn  = s.rn_vei
JOIN tmp_fil_ret fr ON fr.rn = s.rn_fre
JOIN tmp_fil_dev fd ON fd.rn = s.rn_fde;

-- -----------------------------------------------------------------------------
-- 4. Restaura o status dos veículos alterado pelo trigger
-- -----------------------------------------------------------------------------
UPDATE Veiculo v
JOIN tmp_status_veiculo t ON t.id = v.id
SET v.status = t.status;

-- -----------------------------------------------------------------------------
-- 5. Conferência
-- -----------------------------------------------------------------------------
SELECT COUNT(*) AS total_clientes FROM Cliente;
SELECT COUNT(*) AS total_locacoes FROM Locacao;
SELECT status, COUNT(*) AS qtd, ROUND(100 * COUNT(*) / (SELECT COUNT(*) FROM Locacao), 1) AS pct
FROM Locacao GROUP BY status;
SELECT MIN(data_retirada) AS primeira, MAX(data_retirada) AS ultima,
       MIN(valor_total) AS menor_valor, MAX(valor_total) AS maior_valor
FROM Locacao;
SELECT f.cidade, COUNT(*) AS locacoes
FROM Locacao l JOIN Filial f ON f.id = l.id_filial_retirada
GROUP BY f.cidade;
SELECT cidade, COUNT(*) AS clientes FROM Cliente GROUP BY cidade ORDER BY clientes DESC;
SELECT id, nome, cpf, cidade FROM Cliente WHERE nome = 'Cliente teste 4242';
