<?php
// =============================================================================
// Configuração da aplicação — ÚNICO lugar com credenciais do banco.
// A aplicação conecta com o usuário limitado app_locadora (Etapa 5), nunca com root.
// =============================================================================

define('DB_HOST', 'localhost');
// Parte 02: toda a aplicação roda na cópia locadora_lab, nunca no banco original.
define('DB_NAME', 'locadora_lab');
define('DB_USER', 'app_locadora');
define('DB_PASS', 'Loc@App2026!');

// Credenciais usadas SÓ por scripts de linha de comando (migrations, backfill, ETL).
// A aplicação web nunca usa estas constantes: app_locadora não pode alterar esquema.
define('MIG_USER', 'admin_locadora');
define('MIG_PASS', 'Loc@Admin2026!');

define('APP_NOME', 'Locadora v2');

// Prefixo das URLs. Vazio quando a pasta public/ é a raiz do servidor
// (php -S localhost:8000 -t public). Ex.: '/locadora/public' no Apache.
define('BASE_URL', '');

// Em produção deve ficar false: erros não aparecem na tela.
define('APP_DEBUG', false);

// Arquivo de log de erros (Etapa 6). Fica fora de public/.
define('LOG_ERROS', __DIR__ . '/../logs/erros.log');

date_default_timezone_set('America/Sao_Paulo');
