-- =============================================================================
-- Locadora v2 · Etapa 1 — ajustes no esquema do Bimestre I para o CRUD web
-- Executar depois de ../../../locadora_final.sql:
--   mysql -u root locadora < database/01_etapa1_ajustes.sql
--
-- No Bimestre I os ids de Veiculo e Cliente eram informados manualmente.
-- Pelo navegador o usuário não deve escolher o id, então passam a ser
-- AUTO_INCREMENT. As FKs de Locacao apontam para essas colunas, por isso a
-- checagem de FK é desligada só durante a alteração (o tipo INT não muda).
-- =============================================================================

USE locadora;

SET FOREIGN_KEY_CHECKS = 0;
ALTER TABLE Veiculo MODIFY id INT NOT NULL AUTO_INCREMENT;
ALTER TABLE Cliente MODIFY id INT NOT NULL AUTO_INCREMENT;
SET FOREIGN_KEY_CHECKS = 1;
