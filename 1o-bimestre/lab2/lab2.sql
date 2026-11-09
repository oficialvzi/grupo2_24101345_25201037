-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Host: lerd-mysql
-- Generation Time: Sep 28, 2026 at 02:04 PM
-- Server version: 8.4.11
-- PHP Version: 8.3.33

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `Laboratorio1`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`%` PROCEDURE `sp_abrir_locacao` (IN `p_id_cliente` INT, IN `p_id_veiculo` INT, IN `p_id_filial` INT, IN `p_dias_locacao` INT)   BEGIN
    DECLARE v_status VARCHAR(20);
    DECLARE v_diaria DECIMAL(10,2);
    DECLARE v_valor_total DECIMAL(10,2);

    -- 1. Valida disponibilidade
    SELECT status INTO v_status 
    FROM Veiculo 
    WHERE id = p_id_veiculo;

    IF v_status <> 'disponivel' THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Erro: Veiculo indisponivel para locacao.';
    END IF;

    -- 2. Busca diária
    SELECT cat.valor_diaria INTO v_diaria
    FROM Veiculo v
    JOIN Categoria cat ON v.id_categoria = cat.id
    WHERE v.id = p_id_veiculo;

    -- 3. Calcula total e insere
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

--
-- Functions
--
CREATE DEFINER=`root`@`%` FUNCTION `fn_calcula_multa` (`p_id_locacao` INT, `p_taxa_diaria_multa` DECIMAL(10,2)) RETURNS DECIMAL(10,2) DETERMINISTIC BEGIN
    DECLARE v_prevista DATE;
    DECLARE v_real DATE;
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

-- --------------------------------------------------------

--
-- Table structure for table `Categoria`
--

CREATE TABLE `Categoria` (
  `id` int NOT NULL,
  `nome` varchar(50) DEFAULT NULL,
  `valor_diaria` decimal(10,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `Categoria`
--

INSERT INTO `Categoria` (`id`, `nome`, `valor_diaria`) VALUES
(1, 'SUV', 150.00),
(2, 'Econômico', 80.00);

-- --------------------------------------------------------

--
-- Table structure for table `Cliente`
--

CREATE TABLE `Cliente` (
  `id` int NOT NULL,
  `nome` varchar(100) DEFAULT NULL,
  `cpf` varchar(14) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `Cliente`
--

INSERT INTO `Cliente` (`id`, `nome`, `cpf`) VALUES
(1, 'João', '111.222.333-44');

-- --------------------------------------------------------

--
-- Table structure for table `Filial`
--

CREATE TABLE `Filial` (
  `id` int NOT NULL,
  `nome` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `Filial`
--

INSERT INTO `Filial` (`id`, `nome`) VALUES
(1, 'Centro'),
(2, 'Aeroporto');

-- --------------------------------------------------------

--
-- Table structure for table `Locacao`
--

CREATE TABLE `Locacao` (
  `id` int NOT NULL,
  `id_cliente` int DEFAULT NULL,
  `id_veiculo` int DEFAULT NULL,
  `id_filial_retirada` int DEFAULT NULL,
  `id_filial_devolucao` int DEFAULT NULL,
  `data_retirada` date DEFAULT NULL,
  `data_prevista` date DEFAULT NULL,
  `data_real` date DEFAULT NULL,
  `valor_total` decimal(10,2) DEFAULT '0.00',
  `status` varchar(20) DEFAULT 'ativa'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `Locacao`
--

INSERT INTO `Locacao` (`id`, `id_cliente`, `id_veiculo`, `id_filial_retirada`, `id_filial_devolucao`, `data_retirada`, `data_prevista`, `data_real`, `valor_total`, `status`) VALUES
(1, 1, 1, 1, 2, '2026-09-01', '2026-09-05', NULL, 0.00, 'ativa'),
(2, 1, 2, 2, 2, '2026-09-10', '2026-09-12', '2026-09-14', 0.00, 'ativa');

--
-- Triggers `Locacao`
--
DELIMITER $$
CREATE TRIGGER `trg_auditoria_locacao` AFTER UPDATE ON `Locacao` FOR EACH ROW BEGIN
    IF (OLD.valor_total <> NEW.valor_total) OR (OLD.status <> NEW.status) THEN
        INSERT INTO log_locacao (
            id_locacao, valor_antigo, valor_novo,
            status_antigo, status_novo, usuario, data_alteracao
        ) VALUES (
            OLD.id, OLD.valor_total, NEW.valor_total,
            OLD.status, NEW.status, CURRENT_USER(), NOW()
        );
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_locacao_insert` AFTER INSERT ON `Locacao` FOR EACH ROW BEGIN
    UPDATE Veiculo
    SET status = 'locado'
    WHERE id = NEW.id_veiculo;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_locacao_update` AFTER UPDATE ON `Locacao` FOR EACH ROW BEGIN
    IF OLD.data_real IS NULL AND NEW.data_real IS NOT NULL THEN
        UPDATE Veiculo
        SET status = 'disponivel'
        WHERE id = NEW.id_veiculo;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `log_locacao`
--

CREATE TABLE `log_locacao` (
  `id_log` int NOT NULL,
  `id_locacao` int NOT NULL,
  `valor_antigo` decimal(10,2) DEFAULT NULL,
  `valor_novo` decimal(10,2) DEFAULT NULL,
  `status_antigo` varchar(50) DEFAULT NULL,
  `status_novo` varchar(50) DEFAULT NULL,
  `usuario` varchar(100) DEFAULT NULL,
  `data_alteracao` datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `Veiculo`
--

CREATE TABLE `Veiculo` (
  `id` int NOT NULL,
  `placa` varchar(10) NOT NULL,
  `modelo` varchar(50) DEFAULT NULL,
  `id_categoria` int DEFAULT NULL,
  `status` varchar(20) DEFAULT 'disponivel'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `Veiculo`
--

INSERT INTO `Veiculo` (`id`, `placa`, `modelo`, `id_categoria`, `status`) VALUES
(1, 'ABC1234', 'Compass', 1, 'disponivel'),
(2, 'XYZ9876', 'Argo', 2, 'disponivel');

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_faturamento_mensal`
-- (See below for the actual view)
--
CREATE TABLE `vw_faturamento_mensal` (
`mes_ano` varchar(7)
,`id_filial_retirada` int
,`nome_filial` varchar(100)
,`total_faturado` decimal(32,2)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_locacoes_ativas`
-- (See below for the actual view)
--
CREATE TABLE `vw_locacoes_ativas` (
`id_locacao` int
,`nome_cliente` varchar(100)
,`modelo_veiculo` varchar(50)
,`placa` varchar(10)
,`data_retirada` date
,`data_prevista` date
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_veiculos_disponiveis`
-- (See below for the actual view)
--
CREATE TABLE `vw_veiculos_disponiveis` (
`id_veiculo` int
,`modelo` varchar(50)
,`placa` varchar(10)
,`categoria` varchar(50)
,`valor_diaria` decimal(10,2)
);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `Categoria`
--
ALTER TABLE `Categoria`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `Cliente`
--
ALTER TABLE `Cliente`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `cpf` (`cpf`);

--
-- Indexes for table `Filial`
--
ALTER TABLE `Filial`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `Locacao`
--
ALTER TABLE `Locacao`
  ADD PRIMARY KEY (`id`),
  ADD KEY `id_cliente` (`id_cliente`),
  ADD KEY `id_veiculo` (`id_veiculo`),
  ADD KEY `id_filial_retirada` (`id_filial_retirada`),
  ADD KEY `id_filial_devolucao` (`id_filial_devolucao`),
  ADD KEY `idx_locacao_data_retirada` (`data_retirada`);

--
-- Indexes for table `log_locacao`
--
ALTER TABLE `log_locacao`
  ADD PRIMARY KEY (`id_log`);

--
-- Indexes for table `Veiculo`
--
ALTER TABLE `Veiculo`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `placa` (`placa`),
  ADD KEY `idx_veiculo_categoria` (`id_categoria`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `log_locacao`
--
ALTER TABLE `log_locacao`
  MODIFY `id_log` int NOT NULL AUTO_INCREMENT;

-- --------------------------------------------------------

--
-- Structure for view `vw_faturamento_mensal`
--
DROP TABLE IF EXISTS `vw_faturamento_mensal`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `vw_faturamento_mensal`  AS SELECT date_format(`l`.`data_retirada`,'%Y-%m') AS `mes_ano`, `l`.`id_filial_retirada` AS `id_filial_retirada`, `f`.`nome` AS `nome_filial`, sum(`l`.`valor_total`) AS `total_faturado` FROM (`Locacao` `l` join `Filial` `f` on((`l`.`id_filial_retirada` = `f`.`id`))) GROUP BY date_format(`l`.`data_retirada`,'%Y-%m'), `l`.`id_filial_retirada`, `f`.`nome` ;

-- --------------------------------------------------------

--
-- Structure for view `vw_locacoes_ativas`
--
DROP TABLE IF EXISTS `vw_locacoes_ativas`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `vw_locacoes_ativas`  AS SELECT `l`.`id` AS `id_locacao`, `c`.`nome` AS `nome_cliente`, `v`.`modelo` AS `modelo_veiculo`, `v`.`placa` AS `placa`, `l`.`data_retirada` AS `data_retirada`, `l`.`data_prevista` AS `data_prevista` FROM ((`Locacao` `l` join `Cliente` `c` on((`l`.`id_cliente` = `c`.`id`))) join `Veiculo` `v` on((`l`.`id_veiculo` = `v`.`id`))) WHERE (`l`.`data_real` is null) ;

-- --------------------------------------------------------

--
-- Structure for view `vw_veiculos_disponiveis`
--
DROP TABLE IF EXISTS `vw_veiculos_disponiveis`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `vw_veiculos_disponiveis`  AS SELECT `v`.`id` AS `id_veiculo`, `v`.`modelo` AS `modelo`, `v`.`placa` AS `placa`, `cat`.`nome` AS `categoria`, `cat`.`valor_diaria` AS `valor_diaria` FROM (`Veiculo` `v` join `Categoria` `cat` on((`v`.`id_categoria` = `cat`.`id`))) WHERE (`v`.`status` = 'disponivel') ;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `Locacao`
--
ALTER TABLE `Locacao`
  ADD CONSTRAINT `Locacao_ibfk_1` FOREIGN KEY (`id_cliente`) REFERENCES `Cliente` (`id`),
  ADD CONSTRAINT `Locacao_ibfk_2` FOREIGN KEY (`id_veiculo`) REFERENCES `Veiculo` (`id`),
  ADD CONSTRAINT `Locacao_ibfk_3` FOREIGN KEY (`id_filial_retirada`) REFERENCES `Filial` (`id`),
  ADD CONSTRAINT `Locacao_ibfk_4` FOREIGN KEY (`id_filial_devolucao`) REFERENCES `Filial` (`id`);

--
-- Constraints for table `Veiculo`
--
ALTER TABLE `Veiculo`
  ADD CONSTRAINT `Veiculo_ibfk_1` FOREIGN KEY (`id_categoria`) REFERENCES `Categoria` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
