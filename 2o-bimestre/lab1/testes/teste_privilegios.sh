#!/usr/bin/env bash
# Etapa 5: o que cada usuário do SGBD consegue ou não executar.
# Uso: bash testes/teste_privilegios.sh   (a partir da pasta lab1/)
set -uo pipefail

APP_PASS='Loc@App2026!'
ADMIN_PASS='Loc@Admin2026!'

como() {  # como <app|admin> <descricao> <sql>
    local user pass
    if [ "$1" = app ]; then user=app_locadora; pass=$APP_PASS; else user=admin_locadora; pass=$ADMIN_PASS; fi
    local saida
    saida=$(MYSQL_PWD="$pass" mysql -u "$user" --default-character-set=utf8mb4 locadora -N -e "$3" 2>&1)
    if [ $? -eq 0 ]; then printf '  %-15s %-48s PERMITIDO\n' "$user" "$2"
    else printf '  %-15s %-48s NEGADO   -> %s\n' "$user" "$2" "$(echo "$saida" | sed 's/^ERROR /ERROR /' | head -1)"
    fi
}

echo '$ mysql -u root -e "SHOW GRANTS FOR ..."'
mysql -u root -N -e "SHOW GRANTS FOR 'app_locadora'@'localhost'; SHOW GRANTS FOR 'admin_locadora'@'localhost';"

echo
echo '# Preparação (admin_locadora cria uma tabela descartável para os testes)'
como admin "CREATE TABLE teste_privilegio"   "CREATE TABLE teste_privilegio (id INT PRIMARY KEY, txt VARCHAR(20)); INSERT INTO teste_privilegio VALUES (1,'a');"

echo
echo '# app_locadora (SELECT, INSERT, UPDATE)'
como app "SELECT * FROM Veiculo"             "SELECT COUNT(*) FROM Veiculo;"
como app "INSERT INTO teste_privilegio"      "INSERT INTO teste_privilegio VALUES (2,'b');"
como app "UPDATE teste_privilegio"           "UPDATE teste_privilegio SET txt='c' WHERE id=2;"
como app "DELETE FROM teste_privilegio"      "DELETE FROM teste_privilegio WHERE id=2;"
como app "DELETE FROM Cliente WHERE id=5" "DELETE FROM Cliente WHERE id=5;"
como app "DROP TABLE teste_privilegio"       "DROP TABLE teste_privilegio;"
como app "CREATE TABLE outra"                "CREATE TABLE outra (id INT);"
como app "ALTER TABLE Veiculo"               "ALTER TABLE Veiculo ADD COLUMN x INT;"
como app "SELECT em outro banco (mysql.user)" "SELECT user FROM mysql.user LIMIT 1;"
como app "GRANT SELECT ON locadora.*"        "GRANT SELECT ON locadora.* TO 'admin_locadora'@'localhost';"

echo
echo '# admin_locadora (ALL PRIVILEGES em locadora.*)'
como admin "SELECT * FROM Veiculo"           "SELECT COUNT(*) FROM Veiculo;"
como admin "UPDATE teste_privilegio"         "UPDATE teste_privilegio SET txt='d' WHERE id=2;"
como admin "DELETE FROM teste_privilegio"    "DELETE FROM teste_privilegio WHERE id=2;"
como admin "ALTER TABLE teste_privilegio"    "ALTER TABLE teste_privilegio ADD COLUMN x INT;"
como admin "DROP TABLE teste_privilegio"     "DROP TABLE teste_privilegio;"
como admin "SELECT em outro banco (mysql.user)" "SELECT user FROM mysql.user LIMIT 1;"
