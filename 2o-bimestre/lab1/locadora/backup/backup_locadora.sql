-- MySQL dump 10.13  Distrib 8.4.11, for macos26.6 (arm64)
--
-- Host: localhost    Database: locadora
-- ------------------------------------------------------
-- Server version	8.4.11

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Current Database: `locadora`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `locadora` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;

USE `locadora`;

--
-- Table structure for table `Categoria`
--

DROP TABLE IF EXISTS `Categoria`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Categoria` (
  `id` int NOT NULL,
  `nome` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `valor_diaria` decimal(10,2) NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `chk_categoria_valor` CHECK ((`valor_diaria` > 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Categoria`
--

LOCK TABLES `Categoria` WRITE;
/*!40000 ALTER TABLE `Categoria` DISABLE KEYS */;
INSERT INTO `Categoria` VALUES (1,'SUV',150.00),(2,'Econômico',80.00),(3,'Sedan',120.00),(4,'Pickup',200.00),(5,'Executivo',300.00);
/*!40000 ALTER TABLE `Categoria` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Cliente`
--

DROP TABLE IF EXISTS `Cliente`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Cliente` (
  `id` int NOT NULL AUTO_INCREMENT,
  `nome` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `cpf` varchar(14) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `cpf` (`cpf`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Cliente`
--

LOCK TABLES `Cliente` WRITE;
/*!40000 ALTER TABLE `Cliente` DISABLE KEYS */;
INSERT INTO `Cliente` VALUES (1,'João','111.222.333-44'),(2,'Maria','222.333.444-55'),(3,'Carlos','333.444.555-66'),(4,'Ana','444.555.666-77'),(5,'Fernanda','555.666.777-88');
/*!40000 ALTER TABLE `Cliente` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Filial`
--

DROP TABLE IF EXISTS `Filial`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Filial` (
  `id` int NOT NULL,
  `nome` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `cidade` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Filial`
--

LOCK TABLES `Filial` WRITE;
/*!40000 ALTER TABLE `Filial` DISABLE KEYS */;
INSERT INTO `Filial` VALUES (1,'Centro','Brasília'),(2,'Aeroporto','Brasília'),(3,'Asa Norte','Brasília'),(4,'Taguatinga','Brasília'),(5,'Setor Oeste','Goiânia');
/*!40000 ALTER TABLE `Filial` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Locacao`
--

DROP TABLE IF EXISTS `Locacao`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Locacao` (
  `id` int NOT NULL AUTO_INCREMENT,
  `id_cliente` int NOT NULL,
  `id_veiculo` int NOT NULL,
  `id_filial_retirada` int NOT NULL,
  `id_filial_devolucao` int NOT NULL,
  `data_retirada` date NOT NULL,
  `data_prevista` date NOT NULL,
  `data_real` date DEFAULT NULL,
  `valor_total` decimal(10,2) NOT NULL DEFAULT '0.00',
  `status` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'ativa',
  PRIMARY KEY (`id`),
  KEY `id_cliente` (`id_cliente`),
  KEY `id_veiculo` (`id_veiculo`),
  KEY `id_filial_retirada` (`id_filial_retirada`),
  KEY `id_filial_devolucao` (`id_filial_devolucao`),
  KEY `idx_locacao_data_retirada` (`data_retirada`),
  CONSTRAINT `locacao_ibfk_1` FOREIGN KEY (`id_cliente`) REFERENCES `Cliente` (`id`),
  CONSTRAINT `locacao_ibfk_2` FOREIGN KEY (`id_veiculo`) REFERENCES `Veiculo` (`id`),
  CONSTRAINT `locacao_ibfk_3` FOREIGN KEY (`id_filial_retirada`) REFERENCES `Filial` (`id`),
  CONSTRAINT `locacao_ibfk_4` FOREIGN KEY (`id_filial_devolucao`) REFERENCES `Filial` (`id`),
  CONSTRAINT `chk_datas_previstas` CHECK ((`data_prevista` >= `data_retirada`)),
  CONSTRAINT `chk_datas_reais` CHECK (((`data_real` is null) or (`data_real` >= `data_retirada`))),
  CONSTRAINT `chk_valor_total` CHECK ((`valor_total` >= 0))
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Locacao`
--

LOCK TABLES `Locacao` WRITE;
/*!40000 ALTER TABLE `Locacao` DISABLE KEYS */;
INSERT INTO `Locacao` VALUES (1,1,1,1,2,'2026-09-01','2026-09-05',NULL,600.00,'ativa'),(2,1,2,2,2,'2026-09-10','2026-09-12','2026-09-14',160.00,'finalizada'),(3,2,3,1,2,'2026-08-20','2026-08-20','2026-08-20',80.00,'finalizada'),(4,3,4,3,2,'2026-08-25','2026-08-25','2026-08-25',80.00,'finalizada'),(5,4,5,4,2,'2026-09-02','2026-09-02','2026-09-02',80.00,'finalizada'),(7,5,2,1,2,'2026-11-05','2026-11-08','2026-11-07',240.00,'finalizada');
/*!40000 ALTER TABLE `Locacao` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_locacao_insert` AFTER INSERT ON `locacao` FOR EACH ROW BEGIN
    UPDATE Veiculo
    SET status = 'locado'
    WHERE id = NEW.id_veiculo;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_locacao_update` AFTER UPDATE ON `locacao` FOR EACH ROW BEGIN
    IF OLD.data_real IS NULL AND NEW.data_real IS NOT NULL THEN
        UPDATE Veiculo
        SET status = 'disponivel'
        WHERE id = NEW.id_veiculo;
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_auditoria_locacao` AFTER UPDATE ON `locacao` FOR EACH ROW BEGIN
    IF (OLD.valor_total <> NEW.valor_total) OR (OLD.status <> NEW.status) THEN
        INSERT INTO log_locacao (
            id_locacao, valor_antigo, valor_novo,
            status_antigo, status_novo, usuario, data_alteracao
        ) VALUES (
            OLD.id, OLD.valor_total, NEW.valor_total,
            OLD.status, NEW.status, CURRENT_USER(), NOW()
        );
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `log_locacao`
--

DROP TABLE IF EXISTS `log_locacao`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `log_locacao` (
  `id_log` int NOT NULL AUTO_INCREMENT,
  `id_locacao` int NOT NULL,
  `valor_antigo` decimal(10,2) DEFAULT NULL,
  `valor_novo` decimal(10,2) DEFAULT NULL,
  `status_antigo` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status_novo` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `usuario` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `data_alteracao` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_log`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `log_locacao`
--

LOCK TABLES `log_locacao` WRITE;
/*!40000 ALTER TABLE `log_locacao` DISABLE KEYS */;
INSERT INTO `log_locacao` VALUES (2,7,240.00,240.00,'ativa','finalizada','root@localhost','2026-11-05 08:40:04');
/*!40000 ALTER TABLE `log_locacao` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `usuarios`
--

DROP TABLE IF EXISTS `usuarios`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `usuarios` (
  `id` int NOT NULL AUTO_INCREMENT,
  `nome` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `senha_hash` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `perfil` enum('admin','atendente') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'atendente',
  `criado_em` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `usuarios`
--

LOCK TABLES `usuarios` WRITE;
/*!40000 ALTER TABLE `usuarios` DISABLE KEYS */;
INSERT INTO `usuarios` VALUES (1,'Administrador','admin@locadora.local','$2y$12$nz.yYPpq79b3Le1fojc9I.CyewiJT7/DbgVwrXhTxudMU6l6ZS.zG','admin','2026-11-05 08:39:53'),(2,'Atendente','atendente@locadora.local','$2y$12$6wJbrzEbgOfFLDCWHTOHfOwM/cVDCNpc0zVvFhN70P1pxLHaG3H0W','atendente','2026-11-05 08:39:53'),(3,'Pedro Madruga','pedro@locadora.local','$2y$12$WGnaZpTN5PfcF1r3p2wc.u6xecarsZk9gJHV7vWaJskGT1tr10hO.','atendente','2026-11-05 08:40:06');
/*!40000 ALTER TABLE `usuarios` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Veiculo`
--

DROP TABLE IF EXISTS `Veiculo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Veiculo` (
  `id` int NOT NULL AUTO_INCREMENT,
  `placa` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `modelo` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `id_categoria` int NOT NULL,
  `status` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'disponivel',
  `deleted_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `placa` (`placa`),
  KEY `idx_veiculo_categoria` (`id_categoria`),
  CONSTRAINT `veiculo_ibfk_1` FOREIGN KEY (`id_categoria`) REFERENCES `Categoria` (`id`),
  CONSTRAINT `chk_veiculo_status` CHECK ((`status` in (_utf8mb4'disponivel',_utf8mb4'locado')))
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Veiculo`
--

LOCK TABLES `Veiculo` WRITE;
/*!40000 ALTER TABLE `Veiculo` DISABLE KEYS */;
INSERT INTO `Veiculo` VALUES (1,'ABC1234','Compass',1,'locado',NULL),(2,'XYZ9876','Argo',2,'disponivel',NULL),(3,'BRA2E19','Argo',2,'disponivel',NULL),(4,'QWE4R56','Argo',2,'disponivel',NULL),(5,'RTY7U89','Argo',2,'disponivel','2026-11-05 08:39:59');
/*!40000 ALTER TABLE `Veiculo` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary view structure for view `vw_faturamento_mensal`
--

DROP TABLE IF EXISTS `vw_faturamento_mensal`;
/*!50001 DROP VIEW IF EXISTS `vw_faturamento_mensal`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_faturamento_mensal` AS SELECT 
 1 AS `mes_ano`,
 1 AS `id_filial_retirada`,
 1 AS `nome_filial`,
 1 AS `total_faturado`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_locacoes_ativas`
--

DROP TABLE IF EXISTS `vw_locacoes_ativas`;
/*!50001 DROP VIEW IF EXISTS `vw_locacoes_ativas`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_locacoes_ativas` AS SELECT 
 1 AS `id_locacao`,
 1 AS `nome_cliente`,
 1 AS `modelo_veiculo`,
 1 AS `placa`,
 1 AS `data_retirada`,
 1 AS `data_prevista`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_veiculos_disponiveis`
--

DROP TABLE IF EXISTS `vw_veiculos_disponiveis`;
/*!50001 DROP VIEW IF EXISTS `vw_veiculos_disponiveis`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_veiculos_disponiveis` AS SELECT 
 1 AS `id_veiculo`,
 1 AS `modelo`,
 1 AS `placa`,
 1 AS `categoria`,
 1 AS `valor_diaria`*/;
SET character_set_client = @saved_cs_client;

--
-- Dumping routines for database 'locadora'
--
/*!50003 DROP FUNCTION IF EXISTS `fn_calcula_multa` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_calcula_multa`(
    p_id_locacao        INT,
    p_taxa_diaria_multa DECIMAL(10,2)
) RETURNS decimal(10,2)
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_abrir_locacao` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_abrir_locacao`(
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Current Database: `locadora`
--

USE `locadora`;

--
-- Final view structure for view `vw_faturamento_mensal`
--

/*!50001 DROP VIEW IF EXISTS `vw_faturamento_mensal`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_faturamento_mensal` AS select date_format(`l`.`data_retirada`,'%Y-%m') AS `mes_ano`,`l`.`id_filial_retirada` AS `id_filial_retirada`,`f`.`nome` AS `nome_filial`,sum(`l`.`valor_total`) AS `total_faturado` from (`locacao` `l` join `filial` `f` on((`l`.`id_filial_retirada` = `f`.`id`))) group by date_format(`l`.`data_retirada`,'%Y-%m'),`l`.`id_filial_retirada`,`f`.`nome` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_locacoes_ativas`
--

/*!50001 DROP VIEW IF EXISTS `vw_locacoes_ativas`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_locacoes_ativas` AS select `l`.`id` AS `id_locacao`,`c`.`nome` AS `nome_cliente`,`v`.`modelo` AS `modelo_veiculo`,`v`.`placa` AS `placa`,`l`.`data_retirada` AS `data_retirada`,`l`.`data_prevista` AS `data_prevista` from ((`locacao` `l` join `cliente` `c` on((`l`.`id_cliente` = `c`.`id`))) join `veiculo` `v` on((`l`.`id_veiculo` = `v`.`id`))) where (`l`.`data_real` is null) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_veiculos_disponiveis`
--

/*!50001 DROP VIEW IF EXISTS `vw_veiculos_disponiveis`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_veiculos_disponiveis` AS select `v`.`id` AS `id_veiculo`,`v`.`modelo` AS `modelo`,`v`.`placa` AS `placa`,`cat`.`nome` AS `categoria`,`cat`.`valor_diaria` AS `valor_diaria` from (`veiculo` `v` join `categoria` `cat` on((`v`.`id_categoria` = `cat`.`id`))) where ((`v`.`status` = 'disponivel') and (`v`.`deleted_at` is null)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-11-05  8:40:37
