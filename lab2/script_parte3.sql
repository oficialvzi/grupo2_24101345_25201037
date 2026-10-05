-- =====================================================================
-- Laboratório 01 – Parte 2  |  PARTE 3: Concorrência e Transações
-- Banco: Laboratorio1  |  SGBD: MySQL 8.4.11 (InnoDB)
-- Executado em duas sessões simultâneas e independentes (Sessão A / Sessão B)
-- =====================================================================

-- ---------------------------------------------------------------------
-- EXPERIMENTO 3.1 – Bloqueio Explícito (FOR UPDATE)
-- ---------------------------------------------------------------------
-- Sessão A (Aluno A) — passo 1
BEGIN;
SELECT * FROM Veiculo WHERE id = 1 FOR UPDATE;
-- (mantém a transação aberta, SEM COMMIT)

-- Sessão B (Aluno B) — passo 2: fica BLOQUEADA aguardando o lock
BEGIN;
SELECT * FROM Veiculo WHERE id = 1 FOR UPDATE;

-- Sessão A — passo 3: libera a Sessão B imediatamente
COMMIT;

-- Sessão B — passo 4
COMMIT;

-- Consulta auxiliar (3ª sessão) usada para PROVAR o bloqueio:
SELECT r.trx_mysql_thread_id AS thread_bloqueada,
       r.trx_state           AS estado,
       TIMESTAMPDIFF(SECOND, r.trx_wait_started, NOW()) AS segs_esperando,
       b.trx_mysql_thread_id AS thread_bloqueadora
FROM information_schema.innodb_trx r
JOIN performance_schema.data_lock_waits w
  ON r.trx_id = w.REQUESTING_ENGINE_TRANSACTION_ID
JOIN information_schema.innodb_trx b
  ON b.trx_id = w.BLOCKING_ENGINE_TRANSACTION_ID;

-- ---------------------------------------------------------------------
-- EXPERIMENTO 3.2 – Indução de Deadlock
-- ---------------------------------------------------------------------
-- Passo 1 | Sessão A
BEGIN;
-- Passo 2 | Sessão A  (trava a linha de Cliente)
UPDATE Cliente SET nome = 'Teste A' WHERE id = 1;

-- Passo 3 | Sessão B
BEGIN;
-- Passo 4 | Sessão B  (trava a linha de Veiculo)
UPDATE Veiculo SET modelo = 'Teste B' WHERE id = 1;

-- Passo 5 | Sessão A  (fica aguardando o lock que a Sessão B detém)
UPDATE Veiculo SET modelo = 'Teste A' WHERE id = 1;

-- Passo 6 | Sessão B  (fecha o ciclo => DEADLOCK)
UPDATE Cliente SET nome = 'Teste B' WHERE id = 1;
-- ERROR 1213 (40001): Deadlock found when trying to get lock; try restarting transaction

-- Relatório oficial do SGBD sobre o deadlock:
SHOW ENGINE INNODB STATUS;

ROLLBACK; -- em ambas as sessões, para restaurar os dados

-- ---------------------------------------------------------------------
-- EXPERIMENTO 3.3 – Níveis de Isolamento e MVCC
-- ---------------------------------------------------------------------
-- >>> TESTE 1: READ COMMITTED
-- Sessão A
BEGIN;
UPDATE Cliente SET nome = 'ALTERADO POR A' WHERE id = 1;  -- SEM commit

-- Sessão B
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN;
SELECT nome FROM Cliente WHERE id = 1;  -- vê o valor ANTIGO (sem leitura suja)

-- Sessão A
COMMIT;

-- Sessão B (mesma transação, mesma consulta)
SELECT nome FROM Cliente WHERE id = 1;  -- vê o valor NOVO => leitura não repetível
COMMIT;

-- >>> TESTE 2: REPEATABLE READ
-- Sessão B
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN;
SELECT nome FROM Cliente WHERE id = 1;  -- cria o snapshot da transação

-- Sessão A
BEGIN;
UPDATE Cliente SET nome = 'COMMITADO POR A' WHERE id = 1;
COMMIT;

-- Sessão B (mesma transação)
SELECT nome FROM Cliente WHERE id = 1;  -- snapshot MANTIDO: valor inalterado
COMMIT;
SELECT nome FROM Cliente WHERE id = 1;  -- fora da transação: enxerga o valor novo
