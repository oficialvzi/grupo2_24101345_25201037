-- =============================================================================
-- Locadora v2 · Etapa 5 — usuários do SGBD e privilégios
-- Executar como root.
-- =============================================================================

-- Usuário da aplicação: só lê, insere e altera. Sem DELETE e sem DDL.
CREATE USER IF NOT EXISTS 'app_locadora'@'localhost' IDENTIFIED BY 'Loc@App2026!';
ALTER USER 'app_locadora'@'localhost' IDENTIFIED BY 'Loc@App2026!';
GRANT SELECT, INSERT, UPDATE ON locadora.* TO 'app_locadora'@'localhost';

-- Usuário administrativo: todos os privilégios, mas só no banco locadora.
CREATE USER IF NOT EXISTS 'admin_locadora'@'localhost' IDENTIFIED BY 'Loc@Admin2026!';
ALTER USER 'admin_locadora'@'localhost' IDENTIFIED BY 'Loc@Admin2026!';
GRANT ALL PRIVILEGES ON locadora.* TO 'admin_locadora'@'localhost';

FLUSH PRIVILEGES;
