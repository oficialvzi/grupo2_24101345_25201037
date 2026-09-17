DROP DATABASE IF EXISTS locadora;
CREATE DATABASE locadora CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE locadora;

-- =============================================================================
-- ETAPA 4: CRIAÇÃO DAS TABELAS
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
    FOREIGN KEY (id_categoria) REFERENCES Categoria(id)
);

CREATE TABLE Locacao (
    id                   INT   PRIMARY KEY,
    id_cliente           INT   NOT NULL,
    id_veiculo           INT   NOT NULL,
    id_filial_retirada   INT   NOT NULL,
    id_filial_devolucao  INT   NOT NULL,
    data_retirada        DATE  NOT NULL,
    data_prevista        DATE  NOT NULL,
    data_real            DATE  NULL,  -- NULL = locação em aberto
    FOREIGN KEY (id_cliente)          REFERENCES Cliente(id),
    FOREIGN KEY (id_veiculo)          REFERENCES Veiculo(id),
    FOREIGN KEY (id_filial_retirada)  REFERENCES Filial(id),
    FOREIGN KEY (id_filial_devolucao) REFERENCES Filial(id),
    CONSTRAINT chk_datas_previstas CHECK (data_prevista >= data_retirada),
    CONSTRAINT chk_datas_reais     CHECK (data_real IS NULL OR data_real >= data_retirada)
);

-- =============================================================================
-- ETAPA 5: INSERÇÕES (5 registros por tabela)
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

INSERT INTO Veiculo (id, placa, modelo, id_categoria) VALUES
    (1, 'ABC1234', 'Compass', 1),
    (2, 'XYZ9876', 'Argo',    2),
    (3, 'BRA2E19', 'Argo',    2),
    (4, 'QWE4R56', 'Argo',    2),
    (5, 'RTY7U89', 'Argo',    2);

INSERT INTO Locacao (id, id_cliente, id_veiculo, id_filial_retirada, id_filial_devolucao,
                     data_retirada, data_prevista, data_real) VALUES
    (1, 1, 1, 1, 2, '2026-09-01', '2026-09-05', NULL),
    (2, 1, 2, 2, 2, '2026-09-10', '2026-09-12', '2026-09-14'),
    (3, 2, 3, 1, 2, '2026-08-20', '2026-08-20', '2026-08-20'),
    (4, 3, 4, 3, 2, '2026-08-25', '2026-08-25', '2026-08-25'),
    (5, 4, 5, 4, 2, '2026-09-02', '2026-09-02', '2026-09-02');

-- =============================================================================
-- ETAPA 5: CONSULTAS
-- =============================================================================

-- 1. Locações em aberto
SELECT * FROM Locacao WHERE data_real IS NULL;

-- 2. Veículos disponíveis agrupados
SELECT c.nome, v.modelo FROM Veiculo v JOIN Categoria c ON v.id_categoria = c.id WHERE v.id NOT IN (SELECT id_veiculo FROM Locacao WHERE data_real IS NULL) GROUP BY c.nome, v.modelo;

-- 3. Cliente com mais locações
SELECT id_cliente, COUNT(id) FROM Locacao GROUP BY id_cliente ORDER BY COUNT(id) DESC LIMIT 1;

-- 4. Faturamento total por filial
SELECT f.nome, SUM(DATEDIFF(IFNULL(l.data_real, CURDATE()), l.data_retirada) * c.valor_diaria) FROM Locacao l JOIN Veiculo v ON l.id_veiculo = v.id JOIN Categoria c ON v.id_categoria = c.id JOIN Filial f ON l.id_filial_devolucao = f.id GROUP BY f.id;

-- 5. Locações com atraso
SELECT * FROM Locacao WHERE data_real > data_prevista;
