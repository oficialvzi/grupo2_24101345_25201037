# Laboratório 2 (2º Bimestre) — Locadora v2, Parte 02

**Stack:** PHP 8 + MySQL 8.4.11 (PDO) · continuação do `lab1/`
**Roteiro:** [lab2-2obim.md](lab2-2obim.md)

| Integrante | Matrícula |
|---|---|
| Arthur Choi Braga | 24101345 |
| Pedro Emanuel da Costa Madruga | 25201037 |

---

## Estrutura

```
lab2/
├── lab2-2obim.md               # roteiro
├── LEIAME.md
├── respostas.md                # (etapas 1, 2 e 3)
├── evidencias/
└── locadora/                   # cópia do sistema da Parte 01
    ├── config/config.php       # DB_NAME = locadora_lab; MIG_USER/MIG_PASS para scripts CLI
    ├── backup/locadora_backup_parte02.sql   # dump do banco locadora antes da Parte 02
    ├── migrations/             # 001_baseline.sql, ... (Etapas 1, 2 e 3)
    ├── scripts/
    │   ├── preparar_lab.sh     # recria locadora_lab do zero (Etapa 0 inteira)
    │   ├── preparar_esquema.sql # Cliente.cidade e Veiculo.cor (Etapa 0)
    │   ├── gerar_carga.sql     # carga de volume (Etapa 0)
    │   ├── migrate.php         # (Etapa 1)
    │   ├── backfill_cor.php    # (Etapa 1)
    │   └── etl_dw.sql          # (Etapa 3)
    ├── controllers/ models/ views/ core/ public/ logs/
    └── database/               # scripts de criação da Parte 01 (histórico)
```

`migrations/` e `scripts/` ficam fora de `public/`, então não são acessíveis pelo navegador.

---

## Etapa 0 — Preparação

1. **Cópia do banco** (com `--routines` para levar procedure e function junto com os triggers):

   ```bash
   mysqldump -u root --default-character-set=utf8mb4 --routines --triggers locadora > locadora/backup/locadora_backup_parte02.sql
   mysql -u root -e "CREATE DATABASE locadora_lab CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
   mysql -u root --default-character-set=utf8mb4 locadora_lab < locadora/backup/locadora_backup_parte02.sql
   ```

2. **Privilégios na cópia:**

   ```sql
   GRANT SELECT, INSERT, UPDATE ON locadora_lab.* TO 'app_locadora'@'localhost';
   GRANT ALL PRIVILEGES ON locadora_lab.* TO 'admin_locadora'@'localhost';
   FLUSH PRIVILEGES;
   ```

3. **Configuração:** `DB_NAME` aponta para `locadora_lab`; `MIG_USER`/`MIG_PASS` (`admin_locadora`) só para scripts de linha de comando.

4. **Ajustes de esquema** (`scripts/preparar_esquema.sql`, com `admin_locadora`). O roteiro supõe
   `clientes.cidade` e `carros.cor`, que não existiam no nosso esquema. As colunas `Cliente.cidade`
   (`VARCHAR(50) NULL`) e `Veiculo.cor` (`VARCHAR(30) NULL`) são criadas antes da Etapa 1, então o
   `001_baseline` já as inclui. Os 5 clientes e os 5 carros originais (inclusive o carro excluído, id 5)
   recebem cidade e cor. Os CRUDs de Carros e Clientes passaram a exibir, gravar e validar os dois campos.

   ```bash
   mysql -u admin_locadora -p --default-character-set=utf8mb4 locadora_lab < locadora/scripts/preparar_esquema.sql
   ```

5. **Carga de volume** (`scripts/gerar_carga.sql`, executada uma vez com `admin_locadora`, ~3 s):

   ```bash
   mysql -u admin_locadora -p --default-character-set=utf8mb4 locadora_lab < locadora/scripts/gerar_carga.sql
   ```

   | Item | Resultado |
   |---|---|
   | Clientes | 10.005 (5 originais + 10.000 `Cliente teste <n>`, CPF único no formato do sistema: n = 4242 → `000.000.042-42`) |
   | Cidades dos clientes | 6 (Brasília, Goiânia, São Paulo, Rio de Janeiro, Belo Horizonte, Salvador), ~1.650 cada |
   | Locações | 200.006 (6 originais + 200.000) |
   | Status | ativa 24,9% · finalizada 73,1% · cancelada 2,0% |
   | Retiradas | 2023-01-01 a 2025-12-30 (+ as 6 originais de 2026); junho/2025: 5.447 |
   | Valores | 100 a 499 nas geradas |

   O script usa todos os veículos, inclusive o excluído por soft delete (id 5), e guarda e restaura o
   `status` dos veículos, porque o trigger `trg_locacao_insert` marcaria todos como `locado`.

**Tudo de uma vez:** `bash locadora/scripts/preparar_lab.sh` apaga e recria o `locadora_lab` (passos 1 a 5)
em ~3 s. O banco original `locadora` não é alterado.

> Etapa 2, Q5: como o CPF fica com máscara, a comparação vira `WHERE cpf = 4242` (conversão implícita)
> contra `WHERE cpf = '000.000.042-42'`.

---

## Etapa 1 — Migrations (Aula 30)

Comandos a partir de `locadora/`:

```bash
php scripts/migrate.php up       # aplica as pendentes
php scripts/migrate.php down     # desfaz a última
php scripts/backfill_cor.php     # copia cor -> cor_externa em lotes
```

| Passo | O que foi feito |
|---|---|
| Runner | `scripts/migrate.php` = runner da Aula 30 + só CLI + `config.php`/`MIG_USER` + `../migrations/` |
| 001 | `001_baseline.sql` (`DO 0`): marco zero do esquema da Etapa 0 |
| Expandir | `002_add_cor_externa.sql`: `Veiculo.cor_externa VARCHAR(30) NULL`; testado `up`, `down`, `up` |
| Backfill | `scripts/backfill_cor.php`: lotes de 1000, sem filtro de `deleted_at`; checkpoint = 0, incluindo o carro excluído (id 5) |
| Código | `CarroModel`/`CarroController`/views leem só `cor_externa`; `INSERT`/`UPDATE` com escrita dupla |
| Contrair | escrita em `cor` removida do código **antes** da `003_drop_cor.sql`; CRUD testado antes e depois |

`schema_migrations` após a Etapa 1:

```
001_baseline
002_add_cor_externa
003_drop_cor
```

**Cuidado ao recriar o banco** com `scripts/preparar_lab.sh`: o banco volta sem migrations, e
`php scripts/migrate.php up` aplica a 002 e a 003 seguidas, sem espaço para o backfill no meio. O
resultado é `cor_externa` vazia em todos os carros. O runner não tem opção de parar numa versão.

Respostas das perguntas: [respostas.md](respostas.md).
