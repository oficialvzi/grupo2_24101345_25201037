#!/usr/bin/env bash
# Etapa 3 - Parte B: cria teste_restore, faz backup, apaga a tabela e restaura.
# Uso: bash testes/teste_backup_restore.sh   (a partir da pasta lab1/)
set -uo pipefail
cd "$(dirname "$0")/.."
M="mysql -u root --default-character-set=utf8mb4"
BKP=locadora/backup/backup_locadora.sql
run() { echo; echo "\$ $*"; eval "$@"; }

echo '# Etapa 3 - Parte B: backup e restauração'
run "$M locadora -e \"DROP TABLE IF EXISTS teste_restore; CREATE TABLE teste_restore (id INT PRIMARY KEY AUTO_INCREMENT, descricao VARCHAR(100), criado_em DATETIME DEFAULT CURRENT_TIMESTAMP); INSERT INTO teste_restore (descricao) VALUES ('registro 1 antes do backup'), ('registro 2 antes do backup');\" && echo OK"
run "$M -t locadora -e 'SELECT * FROM teste_restore;'"
run "mysqldump -u root --default-character-set=utf8mb4 --routines --triggers --databases locadora > $BKP && echo OK"
run "ls -lh $BKP | awk '{print \$5, \$9}'"
echo "  tabelas no backup:  $(grep -c '^CREATE TABLE' $BKP)"
echo "  triggers no backup: $(grep -cE 'CREATE.*TRIGGER' $BKP)"
echo "  rotinas no backup:  $(grep -cE 'CREATE.*(PROCEDURE|FUNCTION)' $BKP)"
echo; echo '# Simulando a perda de dados'
run "$M locadora -e 'DROP TABLE teste_restore;' && echo OK"
run "$M -t locadora -e 'SELECT * FROM teste_restore;' 2>&1"
echo; echo '# Restaurando a partir do backup'
run "$M < $BKP && echo OK"
run "$M -t locadora -e 'SELECT * FROM teste_restore;'"
run "$M -t locadora -e 'SELECT id, placa, modelo, deleted_at FROM Veiculo;'"
run "$M -t locadora -e \"SELECT TRIGGER_NAME, EVENT_MANIPULATION, ACTION_TIMING FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA='locadora';\""
