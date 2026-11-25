#!/usr/bin/env bash
# =============================================================================
# Locadora v2 · Parte 02 · Etapa 0 — recria o banco locadora_lab do zero
#
#   1. dump do banco original "locadora" (só se o backup ainda não existir)
#   2. APAGA e recria locadora_lab a partir do dump
#   3. GRANTs de app_locadora e admin_locadora na cópia
#   4. preparar_esquema.sql  (Cliente.cidade e Veiculo.cor)   -> admin_locadora
#   5. gerar_carga.sql       (10 mil clientes, 200 mil locações) -> admin_locadora
#
# O banco original "locadora" nunca é alterado.
#
# Uso (a partir de lab2/locadora):
#   bash scripts/preparar_lab.sh                        # root sem senha
#   MYSQL_ROOT_ARGS="-u root -p" bash scripts/preparar_lab.sh
# A senha do admin_locadora é lida de config/config.php (MIG_PASS).
# =============================================================================
set -euo pipefail
cd "$(dirname "$0")/.."

ROOT_ARGS=${MYSQL_ROOT_ARGS:--u root}
CHARSET=--default-character-set=utf8mb4
BACKUP=backup/locadora_backup_parte02.sql
MIG_PASS=$(php -r "require 'config/config.php'; echo MIG_PASS;")

root()  { mysql $ROOT_ARGS $CHARSET "$@"; }
admin() { MYSQL_PWD="$MIG_PASS" mysql -u admin_locadora $CHARSET -t locadora_lab "$@"; }

if [ ! -f "$BACKUP" ]; then
    echo ">> Dump do banco locadora em $BACKUP"
    mysqldump $ROOT_ARGS $CHARSET --routines --triggers locadora > "$BACKUP"
fi

echo ">> Recriando locadora_lab"
root -e "DROP DATABASE IF EXISTS locadora_lab;
         CREATE DATABASE locadora_lab CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
root locadora_lab < "$BACKUP"

echo ">> Privilégios"
root -e "GRANT SELECT, INSERT, UPDATE ON locadora_lab.* TO 'app_locadora'@'localhost';
         GRANT ALL PRIVILEGES ON locadora_lab.* TO 'admin_locadora'@'localhost';
         FLUSH PRIVILEGES;"

echo ">> Ajustes de esquema (cidade e cor)"
admin < scripts/preparar_esquema.sql

echo ">> Carga de volume"
admin < scripts/gerar_carga.sql

echo ">> locadora_lab pronto."
