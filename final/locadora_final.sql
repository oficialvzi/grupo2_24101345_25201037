-- =============================================================================
-- Sistema de Banco de Dados para Locadora de Veículos
-- Script final consolidado: Laboratório 01 + Laboratório 01 – Parte 2 (Lab 2)
--
-- Grupo 2 · Banco de Dados · IDP
--   Arthur Choi Braga (24101345)
--   Pedro Emanuel da Costa Madruga (25201037)
--
-- SGBD: MySQL 8.4 (InnoDB)
-- Execução: mysql -u root -t < locadora_final.sql
--
-- O script recria o banco do zero e executa, na ordem:
--   1. Estrutura (tabelas do Lab 1 já com as colunas acrescentadas no Lab 2)
--   2. Dados de exemplo (5 registros por tabela)
--   3. Consultas do Lab 1
--   4. Views
--   5. Índices, com EXPLAIN antes e depois
--   6. Triggers
--   7. Stored procedure e function
--   8. Testes da Parte 2, dentro de uma transação desfeita ao final
-- Os experimentos de concorrência (Parte 3) estão em concorrencia_parte3.sql,
-- pois exigem duas sessões simultâneas.
-- =============================================================================

DROP DATABASE IF EXISTS locadora;
CREATE DATABASE locadora CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE locadora;

-- =============================================================================
-- 1. ESTRUTURA
-- =============================================================================

CREATE TABLE Categoria (
    id            INT            PRIMARY KEY,
    nome          VARCHAR(50)    NOT NULL,
    valor_diaria  DECIMAL(10,2)  NOT NULL,
    CONSTRAINT chk_categoria_valor CHECK (valor_diaria > 0)
);

CREATE TABLE Filial (
    id      INT           PRIMARY KEY,
    nome    VARCHAR(100)  NOT NULL,
    cidade  VARCHAR(50)   NOT NULL
);

CREATE TABLE Cliente (
    id    INT           PRIMARY KEY,
    nome  VARCHAR(100)  NOT NULL,
    cpf   VARCHAR(14)   UNIQUE NOT NULL
);

CREATE TABLE Veiculo (
    id            INT          PRIMARY KEY,
    placa         VARCHAR(10)  UNIQUE NOT NULL,
    modelo        VARCHAR(50)  NOT NULL,
    id_categoria  INT          NOT NULL,
    status        VARCHAR(20)  NOT NULL DEFAULT 'disponivel',   -- Lab 2
    FOREIGN KEY (id_categoria) REFERENCES Categoria(id),
    CONSTRAINT chk_veiculo_status CHECK (status IN ('disponivel', 'locado'))
);

CREATE TABLE Locacao (
    id                   INT            PRIMARY KEY AUTO_INCREMENT,
    id_cliente           INT            NOT NULL,
    id_veiculo           INT            NOT NULL,
    id_filial_retirada   INT            NOT NULL,
    id_filial_devolucao  INT            NOT NULL,
    data_retirada        DATE           NOT NULL,
    data_prevista        DATE           NOT NULL,
    data_real            DATE           NULL,                        -- NULL = locação em aberto
    valor_total          DECIMAL(10,2)  NOT NULL DEFAULT 0.00,       -- Lab 2
    status               VARCHAR(20)    NOT NULL DEFAULT 'ativa',    -- Lab 2
    FOREIGN KEY (id_cliente)          REFERENCES Cliente(id),
    FOREIGN KEY (id_veiculo)          REFERENCES Veiculo(id),
    FOREIGN KEY (id_filial_retirada)  REFERENCES Filial(id),
    FOREIGN KEY (id_filial_devolucao) REFERENCES Filial(id),
    CONSTRAINT chk_datas_previstas CHECK (data_prevista >= data_retirada),
    CONSTRAINT chk_datas_reais     CHECK (data_real IS NULL OR data_real >= data_retirada),
    CONSTRAINT chk_valor_total     CHECK (valor_total >= 0)
);

-- Tabela de auditoria (Lab 2, Exercício 2.1)
CREATE TABLE log_locacao (
    id_log          INT            PRIMARY KEY AUTO_INCREMENT,
    id_locacao      INT            NOT NULL,
    valor_antigo    DECIMAL(10,2),
    valor_novo      DECIMAL(10,2),
    status_antigo   VARCHAR(50),
    status_novo     VARCHAR(50),
    usuario         VARCHAR(100),
    data_alteracao  DATETIME       DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- 2. DADOS DE EXEMPLO
-- Ordem das dependências de chave estrangeira:
-- Categoria, Filial e Cliente -> Veiculo -> Locacao
-- =============================================================================

INSERT INTO Categoria (id, nome, valor_diaria) VALUES
    (1, 'SUV',       150.00),
    (2, 'Econômico',  80.00),
    (3, 'Sedan',     120.00),
    (4, 'Pickup',    200.00),
    (5, 'Executivo', 300.00);

INSERT INTO Filial (id, nome, cidade) VALUES
    (1, 'Centro',      'Brasília'),
    (2, 'Aeroporto',   'Brasília'),
    (3, 'Asa Norte',   'Brasília'),
    (4, 'Taguatinga',  'Brasília'),
    (5, 'Setor Oeste', 'Goiânia');

INSERT INTO Cliente (id, nome, cpf) VALUES
    (1, 'João',     '111.222.333-44'),
    (2, 'Maria',    '222.333.444-55'),
    (3, 'Carlos',   '333.444.555-66'),
    (4, 'Ana',      '444.555.666-77'),
    (5, 'Fernanda', '555.666.777-88');

-- O veículo 1 está na locação em aberto, por isso já começa como 'locado'.
INSERT INTO Veiculo (id, placa, modelo, id_categoria, status) VALUES
    (1, 'ABC1234', 'Compass', 1, 'locado'),
    (2, 'XYZ9876', 'Argo',    2, 'disponivel'),
    (3, 'BRA2E19', 'Argo',    2, 'disponivel'),
    (4, 'QWE4R56', 'Argo',    2, 'disponivel'),
    (5, 'RTY7U89', 'Argo',    2, 'disponivel');

-- valor_total = diária x dias previstos (mínimo de 1 diária), o mesmo cálculo
-- feito por sp_abrir_locacao. Locações devolvidas ficam com status 'finalizada'.
INSERT INTO Locacao (id, id_cliente, id_veiculo, id_filial_retirada, id_filial_devolucao,
                     data_retirada, data_prevista, data_real, valor_total, status) VALUES
    (1, 1, 1, 1, 2, '2026-09-01', '2026-09-05', NULL,         600.00, 'ativa'),
    (2, 1, 2, 2, 2, '2026-09-10', '2026-09-12', '2026-09-14', 160.00, 'finalizada'),
    (3, 2, 3, 1, 2, '2026-08-20', '2026-08-20', '2026-08-20',  80.00, 'finalizada'),
    (4, 3, 4, 3, 2, '2026-08-25', '2026-08-25', '2026-08-25',  80.00, 'finalizada'),
    (5, 4, 5, 4, 2, '2026-09-02', '2026-09-02', '2026-09-02',  80.00, 'finalizada');

-- =============================================================================
-- 3. CONSULTAS DO LAB 1
-- =============================================================================

-- 3.1 Locações em aberto
SELECT * FROM Locacao WHERE data_real IS NULL;

-- 3.2 Veículos disponíveis agrupados por categoria e modelo
SELECT c.nome AS categoria, v.modelo
FROM Veiculo v
JOIN Categoria c ON v.id_categoria = c.id
WHERE v.id NOT IN (SELECT id_veiculo FROM Locacao WHERE data_real IS NULL)
GROUP BY c.nome, v.modelo;

-- 3.3 Cliente com mais locações
SELECT id_cliente, COUNT(id) AS total_locacoes
FROM Locacao
GROUP BY id_cliente
ORDER BY COUNT(id) DESC
LIMIT 1;

-- 3.4 Faturamento total por filial de devolução
--     (locação em aberto usa a data atual, então o valor muda a cada dia)
SELECT f.nome AS filial,
       SUM(DATEDIFF(IFNULL(l.data_real, CURDATE()), l.data_retirada) * c.valor_diaria) AS faturamento
FROM Locacao l
JOIN Veiculo v   ON l.id_veiculo = v.id
JOIN Categoria c ON v.id_categoria = c.id
JOIN Filial f    ON l.id_filial_devolucao = f.id
GROUP BY f.id, f.nome;

-- 3.5 Locações com atraso
SELECT * FROM Locacao WHERE data_real > data_prevista;

-- =============================================================================
-- 4. VIEWS (Lab 2, Exercício 1.1)
-- =============================================================================

CREATE VIEW vw_locacoes_ativas AS
SELECT l.id            AS id_locacao,
       c.nome          AS nome_cliente,
       v.modelo        AS modelo_veiculo,
       v.placa         AS placa,
       l.data_retirada AS data_retirada,
       l.data_prevista AS data_prevista
FROM Locacao l
JOIN Cliente c ON l.id_cliente = c.id
JOIN Veiculo v ON l.id_veiculo = v.id
WHERE l.data_real IS NULL;

CREATE VIEW vw_veiculos_disponiveis AS
SELECT v.id             AS id_veiculo,
       v.modelo         AS modelo,
       v.placa          AS placa,
       cat.nome         AS categoria,
       cat.valor_diaria AS valor_diaria
FROM Veiculo v
JOIN Categoria cat ON v.id_categoria = cat.id
WHERE v.status = 'disponivel';

CREATE VIEW vw_faturamento_mensal AS
SELECT DATE_FORMAT(l.data_retirada, '%Y-%m') AS mes_ano,
       l.id_filial_retirada                  AS id_filial_retirada,
       f.nome                                AS nome_filial,
       SUM(l.valor_total)                    AS total_faturado
FROM Locacao l
JOIN Filial f ON l.id_filial_retirada = f.id
GROUP BY DATE_FORMAT(l.data_retirada, '%Y-%m'), l.id_filial_retirada, f.nome;

SELECT * FROM vw_locacoes_ativas;
SELECT * FROM vw_veiculos_disponiveis;
SELECT * FROM vw_faturamento_mensal ORDER BY mes_ano, id_filial_retirada;

-- =============================================================================
-- 5. ÍNDICES E PLANO DE EXECUÇÃO (Lab 2, Exercício 1.2)
-- =============================================================================

-- 5.1 EXPLAIN ANTES dos índices
-- Consulta A: cliente por CPF
EXPLAIN SELECT * FROM Cliente WHERE cpf = '333.444.555-66';
-- Consulta B: locações por intervalo de datas de retirada
EXPLAIN SELECT * FROM Locacao WHERE data_retirada BETWEEN '2026-09-01' AND '2026-09-10';
-- Consulta C: veículos por categoria
EXPLAIN SELECT * FROM Veiculo WHERE id_categoria = 2;

-- 5.2 Criação dos índices
-- Consulta A já é atendida pelo índice único criado pela restrição UNIQUE de cpf.
CREATE INDEX idx_locacao_data_retirada ON Locacao (data_retirada);
CREATE INDEX idx_veiculo_categoria     ON Veiculo (id_categoria);

-- 5.3 EXPLAIN DEPOIS dos índices
EXPLAIN SELECT * FROM Cliente WHERE cpf = '333.444.555-66';
EXPLAIN SELECT * FROM Locacao WHERE data_retirada BETWEEN '2026-09-01' AND '2026-09-10';
EXPLAIN SELECT * FROM Veiculo WHERE id_categoria = 2;

SHOW INDEX FROM Veiculo;

-- =============================================================================
-- 6. TRIGGERS (Lab 2, Exercício 2.1)
-- Criados depois da carga inicial para não alterar o status dos dados de exemplo.
-- =============================================================================

DELIMITER $$

-- 6.1 Ao abrir uma locação, o veículo passa a 'locado'
CREATE TRIGGER trg_locacao_insert
AFTER INSERT ON Locacao
FOR EACH ROW
BEGIN
    UPDATE Veiculo
    SET status = 'locado'
    WHERE id = NEW.id_veiculo;
END$$

-- 6.2 Ao registrar a devolução (data_real preenchida), o veículo volta a 'disponivel'
CREATE TRIGGER trg_locacao_update
AFTER UPDATE ON Locacao
FOR EACH ROW
BEGIN
    IF OLD.data_real IS NULL AND NEW.data_real IS NOT NULL THEN
        UPDATE Veiculo
        SET status = 'disponivel'
        WHERE id = NEW.id_veiculo;
    END IF;
END$$

-- 6.3 Auditoria: registra mudanças de valor_total ou status da locação
CREATE TRIGGER trg_auditoria_locacao
AFTER UPDATE ON Locacao
FOR EACH ROW
BEGIN
    IF (OLD.valor_total <> NEW.valor_total) OR (OLD.status <> NEW.status) THEN
        INSERT INTO log_locacao (
            id_locacao, valor_antigo, valor_novo,
            status_antigo, status_novo, usuario, data_alteracao
        ) VALUES (
            OLD.id, OLD.valor_total, NEW.valor_total,
            OLD.status, NEW.status, CURRENT_USER(), NOW()
        );
    END IF;
END$$

-- =============================================================================
-- 7. PROCEDURE E FUNCTION (Lab 2, Exercício 2.2)
-- =============================================================================

-- 7.1 Abre uma locação validando a disponibilidade do veículo
CREATE PROCEDURE sp_abrir_locacao (
    IN p_id_cliente   INT,
    IN p_id_veiculo   INT,
    IN p_id_filial    INT,
    IN p_dias_locacao INT
)
BEGIN
    DECLARE v_status      VARCHAR(20);
    DECLARE v_diaria      DECIMAL(10,2);
    DECLARE v_valor_total DECIMAL(10,2);

    -- 1. Valida disponibilidade
    SELECT status INTO v_status
    FROM Veiculo
    WHERE id = p_id_veiculo;

    IF v_status <> 'disponivel' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erro: Veiculo indisponivel para locacao.';
    END IF;

    -- 2. Busca a diária da categoria
    SELECT cat.valor_diaria INTO v_diaria
    FROM Veiculo v
    JOIN Categoria cat ON v.id_categoria = cat.id
    WHERE v.id = p_id_veiculo;

    -- 3. Calcula o total e insere
    SET v_valor_total = v_diaria * p_dias_locacao;

    INSERT INTO Locacao (
        id_cliente, id_veiculo, id_filial_retirada, id_filial_devolucao,
        data_retirada, data_prevista, valor_total, status
    ) VALUES (
        p_id_cliente, p_id_veiculo, p_id_filial, p_id_filial,
        CURDATE(), DATE_ADD(CURDATE(), INTERVAL p_dias_locacao DAY),
        v_valor_total, 'ativa'
    );
END$$

-- 7.2 Calcula a multa por atraso de uma locação
CREATE FUNCTION fn_calcula_multa (
    p_id_locacao        INT,
    p_taxa_diaria_multa DECIMAL(10,2)
)
RETURNS DECIMAL(10,2)
READS SQL DATA
BEGIN
    DECLARE v_prevista    DATE;
    DECLARE v_real        DATE;
    DECLARE v_dias_atraso INT;

    SELECT data_prevista, data_real
    INTO v_prevista, v_real
    FROM Locacao
    WHERE id = p_id_locacao;

    IF v_real IS NOT NULL AND v_real > v_prevista THEN
        SET v_dias_atraso = DATEDIFF(v_real, v_prevista);
        RETURN v_dias_atraso * p_taxa_diaria_multa;
    END IF;

    RETURN 0.00;
END$$

DELIMITER ;

-- =============================================================================
-- 8. TESTES DA PARTE 2
-- Executados dentro de uma transação e desfeitos no final (ROLLBACK),
-- para que o banco permaneça com os dados de exemplo originais.
-- =============================================================================

START TRANSACTION;

-- 8.1 Function: locação 2 atrasou 2 dias; locação 3 foi devolvida no prazo
SELECT fn_calcula_multa(2, 50.00) AS multa_locacao_2,
       fn_calcula_multa(3, 50.00) AS multa_locacao_3;

-- 8.2 Procedure + trigger de INSERT: abre locação do veículo 3 (Argo) por 3 dias
CALL sp_abrir_locacao(5, 3, 1, 3);
SELECT id, id_cliente, id_veiculo, data_retirada, data_prevista, valor_total, status
FROM Locacao ORDER BY id DESC LIMIT 1;
SELECT id, modelo, status FROM Veiculo WHERE id = 3;

-- 8.3 Procedure com veículo indisponível (veículo 1 está locado).
--     Descomente para ver o erro 1644 (SQLSTATE 45000):
-- CALL sp_abrir_locacao(2, 1, 1, 2);

-- 8.4 Trigger de UPDATE + auditoria: devolução da locação 1
UPDATE Locacao
SET data_real = '2026-09-06', status = 'finalizada'
WHERE id = 1;
SELECT id, modelo, status FROM Veiculo WHERE id = 1;
SELECT id_locacao, status_antigo, status_novo, valor_antigo, valor_novo, usuario
FROM log_locacao;

ROLLBACK;
