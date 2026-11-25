# Como preparar o ambiente para a Etapa 2

Passo a passo para baixar o repositório e montar o banco `locadora_lab` no mesmo estado em que a
Etapa 1 terminou. Leva uns 5 minutos.

**Pré-requisitos:** MySQL 8.0.18 ou superior, PHP 8 com `pdo_mysql` e Git.

---

## 1. Atualizar o repositório

Se você já tem o repositório clonado:

```bash
cd grupo2_24101345_25201037
git pull
```

Se ainda não tem:

```bash
git clone https://github.com/oficialvzi/grupo2_24101345_25201037.git
cd grupo2_24101345_25201037
```

Daqui em diante, **todos os comandos rodam a partir de `2o-bimestre/lab2/locadora`**:

```bash
cd 2o-bimestre/lab2/locadora
```

---

## 2. Conferir o MySQL

```bash
mysql -u root -p -e "SELECT VERSION();"
```

Precisa ser **8.0.18 ou superior** (por causa do `EXPLAIN ANALYZE`).

> Se o seu `root` não tem senha, tire o `-p` de todos os comandos deste guia.

---

## 3. Criar os usuários do banco (só se ainda não existirem)

O sistema usa `app_locadora` e as migrations usam `admin_locadora`, com as senhas que estão em
`config/config.php`. Se você fez a Parte 01 nesta máquina, eles já existem. Para garantir, rode
(pode rodar mesmo se já existirem, não estraga nada):

```bash
mysql -u root -p < database/03_etapa5_privilegios.sql
```

---

## 4. Recriar o banco `locadora_lab`

O script abaixo **apaga e recria** o `locadora_lab` a partir do backup que está no repositório,
dá os `GRANT`, cria `Cliente.cidade` e `Veiculo.cor` e gera a carga de volume (10 mil clientes e
200 mil locações). O banco `locadora` original não é tocado.

```bash
MYSQL_ROOT_ARGS="-u root -p" bash scripts/preparar_lab.sh
```

Ele pede a senha do root algumas vezes. Se o root não tem senha, rode só
`bash scripts/preparar_lab.sh`.

No final deve aparecer `>> locadora_lab pronto.`, com 10005 clientes e 200006 locações.

---

## 5. Aplicar as migrations da Etapa 1

```bash
php scripts/migrate.php up
```

Deve mostrar:

```
Aplicada: 001_baseline
Aplicada: 002_add_cor_externa
Aplicada: 003_drop_cor
```

**Importante:** como o runner aplica a 002 e a 003 seguidas, não sobra espaço para o backfill no
meio, e os carros ficam sem cor. Para devolver as cores dos 5 carros originais:

```bash
mysql -u root -p locadora_lab -e "UPDATE Veiculo SET cor_externa = ELT(id, 'Preto','Branco','Prata','Vermelho','Cinza') WHERE id BETWEEN 1 AND 5;"
```

---

## 6. Conferir se ficou tudo igual

```bash
mysql -u root -p locadora_lab -e "SELECT * FROM schema_migrations; SELECT id, placa, modelo, cor_externa, deleted_at FROM Veiculo; SELECT COUNT(*) FROM Locacao; SHOW INDEX FROM Locacao;"
```

O esperado:
- `schema_migrations` com `001_baseline`, `002_add_cor_externa` e `003_drop_cor`;
- 5 carros, todos com `cor_externa` (o carro 5 com `deleted_at` preenchido);
- 200006 locações.

Abrir o sistema:

```bash
php -S localhost:8000 -t public
```

Acesse http://localhost:8000 e entre com o usuário admin que está em `database/criar_admin.php`.

---

## 7. Avisos para a Etapa 2

- **Nomes das tabelas e colunas.** O roteiro usa os nomes genéricos; no nosso esquema eles são estes:

  | Roteiro | Nosso esquema |
  |---|---|
  | `locacoes` | `Locacao` |
  | `clientes` | `Cliente` |
  | `carros` | `Veiculo` |
  | `cliente_id` | `id_cliente` |
  | `carro_id` | `id_veiculo` |
  | `valor` | `valor_total` |
  | `data_devolucao` | `data_real` (NULL = locação aberta) |

- **Índice que já existe.** O `Locacao` já tem `idx_locacao_data_retirada`, criado no Bimestre I.
  Por isso a Q1 provavelmente já usa índice no "antes". Vejam no `SHOW INDEX FROM Locacao;` e anotem.
- **Numeração das migrations.** As da Etapa 2 começam em `004`. Cada arquivo tem `-- up` e `-- down`,
  com **uma instrução** em cada seção. Aplique com `php scripts/migrate.php up`.
- **Nunca editem uma migration já aplicada.** Se errar, criem uma nova que corrige.
- **Q4.** O cliente `4242` existe, pode usar.
- **Q5 (CPF).** Os CPFs estão com máscara. Compare `WHERE cpf = 4242` com
  `WHERE cpf = '000.000.042-42'`. O `cpf` já tem índice (é `UNIQUE`), então a `007_idx_clientes_cpf`
  provavelmente não é necessária, e o BI da Etapa 3 começa na `007`.
- **Respostas** vão em `2o-bimestre/lab2/respostas.md` (já tem a Etapa 1) e a tabela de registro do
  `EXPLAIN` vai no `LEIAME.md`.
- **Se precisar recomeçar do zero**, repita os passos 4 e 5. As migrations da Etapa 2 que já
  estiverem no repositório também serão aplicadas pelo `up`.
