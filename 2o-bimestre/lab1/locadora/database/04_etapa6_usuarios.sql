-- =============================================================================
-- Locadora v2 · Etapa 6 — usuários do sistema (login)
-- =============================================================================

USE locadora;

CREATE TABLE IF NOT EXISTS usuarios (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    nome        VARCHAR(100) NOT NULL,
    email       VARCHAR(150) NOT NULL UNIQUE,
    senha_hash  VARCHAR(255) NOT NULL,
    perfil      ENUM('admin','atendente') NOT NULL DEFAULT 'atendente',
    criado_em   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
