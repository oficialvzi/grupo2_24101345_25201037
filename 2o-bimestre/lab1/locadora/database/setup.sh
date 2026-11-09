#!/usr/bin/env bash
# Recria o banco "locadora" do zero: esquema do Bimestre I + ajustes da v2.
# Uso: bash database/setup.sh            (usuário root sem senha)
#      MYSQL_ARGS="-u root -p" bash database/setup.sh
#
# --default-character-set=utf8mb4 é obrigatório: o cliente mysql desta máquina
# usa latin1 por padrão e gravaria "Econômico" como "EconÃ´mico".
set -euo pipefail
cd "$(dirname "$0")"
MYSQL="mysql ${MYSQL_ARGS:--u root} --default-character-set=utf8mb4"

$MYSQL < ../../../locadora_final.sql > /dev/null
$MYSQL locadora < 01_etapa1_ajustes.sql
$MYSQL locadora < 02_etapa3_soft_delete.sql
$MYSQL < 03_etapa5_privilegios.sql
$MYSQL locadora < 04_etapa6_usuarios.sql
php criar_admin.php
echo "Banco 'locadora' criado e atualizado."
