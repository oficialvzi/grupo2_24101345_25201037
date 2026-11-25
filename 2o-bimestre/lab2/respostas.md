# Respostas — Laboratório Locadora v2 (Parte 02)

Grupo 2 · Arthur Choi Braga (24101345) · Pedro Emanuel da Costa Madruga (25201037)

> No nosso esquema a tabela `carros` do roteiro se chama `Veiculo`.

---

## Etapa 1 — Migrations

### 1. Privilégio

**Por que o runner usa `MIG_USER` e não `app_locadora`?**

Migrations alteram o esquema (`ALTER`, `CREATE`, `DROP`) e o `app_locadora` não tem esses
privilégios: desde a Parte 01, Etapa 5, ele só tem `SELECT, INSERT, UPDATE`. Esse é o princípio do
menor privilégio. A aplicação web é a parte mais exposta do sistema; se ela for invadida (por
exemplo, por SQL Injection), o atacante fica limitado ao que o `app_locadora` pode fazer e não
consegue apagar tabelas nem mudar a estrutura. Mudar o esquema é tarefa de manutenção, feita pela
linha de comando com o usuário administrativo (`admin_locadora`). Por isso o runner também recusa
rodar pelo navegador.

Teste com `app_locadora` no cliente `mysql`:

```
mysql> ALTER TABLE Veiculo ADD COLUMN x INT;
ERROR 1142 (42000): ALTER command denied to user 'app_locadora'@'localhost' for table 'veiculo'
```

Com `app_locadora`, o runner falharia já na primeira linha, ao tentar criar a `schema_migrations`:

```
ERROR 1142 (42000): CREATE command denied to user 'app_locadora'@'localhost' for table 'teste_x'
```

### 2. NOT NULL

**O que aconteceria com o código que ainda não conhece `cor_externa` se ela fosse `NOT NULL` sem
valor padrão?**

Todo cadastro de carro pelo sistema passaria a falhar. O `INSERT` do código antigo não informa
`cor_externa`, e no modo estrito do MySQL (`STRICT_TRANS_TABLES`, ativo no nosso servidor) uma
coluna `NOT NULL` sem `DEFAULT` não pode ficar sem valor. O erro aparece entre o momento em que a
migration é aplicada e o momento em que o código novo entra no ar, exatamente a janela que o
expandir/contrair quer eliminar.

Teste em uma tabela temporária com a mesma estrutura, simulando o `INSERT` do código antigo:

```
ERROR 1364 (HY000): Field 'cor_externa' doesn't have a default value
```

Por isso a coluna nasce `NULL`. Se ela precisar ser `NOT NULL`, isso vira uma migration posterior,
aplicada depois do backfill e depois de o código já gravar sempre o campo.

### 3. Soft delete

**Por que o backfill não filtra `deleted_at IS NULL`? O que o usuário veria ao restaurar um carro
que ficou de fora?**

No soft delete o carro "excluído" continua no banco: ele só fica escondido das listagens e pode ser
restaurado (basta voltar `deleted_at` para `NULL`). Ele também continua ligado ao histórico de
locações e vai entrar na dimensão de carros do BI (Etapa 3). Para o banco, ele é um registro como
qualquer outro e precisa migrar junto.

Se o backfill filtrasse `deleted_at IS NULL`, o carro 5 (RTY7U89, excluído) ficaria com
`cor_externa = NULL`. Depois da `003`, a coluna `cor` não existe mais, então a cor dele estaria
perdida. Ao restaurar o carro, o usuário veria o carro **sem cor** na listagem e no formulário de
edição, e precisaria digitar a cor de novo sem saber qual era. No nosso banco o checkpoint deu
**0**, contando o carro 5:

```
5  RTY7U89  Argo  cor = Cinza  cor_externa = Cinza  deleted_at = 2026-11-05 08:39:59
```

### 4. Irreversível

**Rodem `down` logo após a `003`. A coluna `cor` volta, mas os dados voltam?**

A coluna volta, os dados não. O `down` executa `ALTER TABLE Veiculo ADD COLUMN cor VARCHAR(30) NULL`,
que cria uma coluna nova e vazia:

```
$ php scripts/migrate.php down
Desfeita: 003_drop_cor

id  placa    cor   cor_externa  deleted_at
1   ABC1234  NULL  Preto        NULL
2   XYZ9876  NULL  Branco       NULL
3   BRA2E19  NULL  Prata        NULL
4   QWE4R56  NULL  Vermelho     NULL
5   RTY7U89  NULL  Cinza        2026-11-05 08:39:59
8   ABC1235  NULL  Preto        NULL
```

(Depois do teste, reaplicamos a `003` com `up`.)

**O que o `down` não consegue desfazer e o que usaríamos para recuperar?**

O `down` desfaz a **estrutura**, não os **dados**. O `DROP COLUMN` apagou os valores de `cor`, e
nenhuma instrução SQL consegue recriá-los a partir do nada. A recuperação usa **backup**, como na
Parte 01, Etapa 3:

1. Antes de uma migration destrutiva, gerar um dump: `mysqldump ... locadora_lab > antes_003.sql`.
2. Para recuperar, restaurar o dump em um banco separado (`mysql ... locadora_restore < antes_003.sql`)
   e copiar a coluna de volta com um `UPDATE ... JOIN` pelo `id`. Restaurar por cima do
   `locadora_lab` apagaria o que mudou depois do backup.

No nosso caso os dados estão salvos por outro motivo: o backfill já tinha copiado tudo para
`cor_externa`. Mas isso só vale porque o expandir/contrair foi seguido na ordem. Vale notar também
que o nosso `backup/locadora_backup_parte02.sql` foi feito **antes** da Etapa 0 criar a coluna `cor`,
então não serviria para recuperá-la. Na prática, o backup tem que ser feito imediatamente antes da
migration destrutiva.

**Por que, ao descobrir que `cor_externa` deveria ter 40 caracteres, não se edita a `002`, e qual
migration se cria?**

A `002` já está registrada na `schema_migrations` de todo banco onde rodou: o nosso, o do colega e,
num sistema real, o de produção. O runner pula migrations já registradas, então a `002` editada
**nunca rodaria de novo** nesses bancos. Só um banco criado do zero teria a coluna com 40
caracteres; os outros continuariam com 30. Os ambientes ficariam diferentes sem que nada indicasse
isso, e o histórico deixaria de contar o que realmente aconteceu.

O certo é criar uma **migration nova**, com o próximo número livre (no nosso caso, depois das
migrations de índice da Etapa 2):

```sql
-- 0XX_cor_externa_40.sql
-- up
ALTER TABLE Veiculo MODIFY COLUMN cor_externa VARCHAR(40) NULL;

-- down
ALTER TABLE Veiculo MODIFY COLUMN cor_externa VARCHAR(30) NULL;
```

(O `down` só funciona se nenhum valor tiver passado de 30 caracteres; senão o MySQL recusa a
mudança em modo estrito.)

---

## Etapa 2 — Otimização de consultas

Índices criados por migration (com `down`, testado com `down` seguido de `up`):

| Migration | Índice | Motivo |
|---|---|---|
| `004_idx_clientes_nome.sql` | `Cliente(nome)` | busca por prefixo (Q3 reescrita) |
| `005_idx_locacao_cliente_data.sql` | `Locacao(id_cliente, data_retirada)` | cliente + período (Q4) |

Não criamos a `004` de `locacoes(data_retirada)` do roteiro: `idx_locacao_data_retirada` já existe
desde o Bimestre I e a Q1 já o usa. Um segundo índice igual só duplicaria o custo de escrita. A
numeração ficou em 004 e 005, e o `cpf` não precisou de índice novo porque já é `UNIQUE`.

### Registro do EXPLAIN

| Consulta | type antes | key antes | rows antes | type depois | key depois | rows depois |
|---|---|---|---|---|---|---|
| Q1 (faixa de datas) | range | idx_locacao_data_retirada | 5.447 | range | idx_locacao_data_retirada | 5.447 |
| Q2 (`DATE_FORMAT`) → faixa | ALL | NULL | 199.248 | range | idx_locacao_data_retirada | 5.447 |
| Q3 (`LIKE '%123'`) → prefixo | ALL | NULL | 10.177 | range | idx_cliente_nome | 11 |
| Q4 (cliente + data) | ref | id_cliente | 20 | range | idx_loc_cliente_data | 2 |
| Q5 (`cpf = 4242`, número) | ALL | NULL | 10.177 | ALL | NULL | 10.180 |
| Q5 (`cpf = '000.000.042-42'`, texto) | const | cpf | 1 | const | cpf | 1 |

Q5 com número (`WHERE cpf = 4242`) continua `ALL` depois dos índices: é a conversão implícita que
impede o uso do índice `cpf`. A versão com texto já usava o índice `UNIQUE` do `cpf` antes da
Etapa 2, então ela não tem ganho para registrar; serve de contraste.

Tempo real da Q1 (`EXPLAIN ANALYZE`): antes 15,1 ms (uma execução); depois 17,6 ms (mediana de cinco).
Não há ganho nessa consulta, porque o índice que ela usa já existia antes.

Tempo real das consultas reescritas (mediana de três a seis execuções):

| Consulta | antes | depois |
|---|---|---|
| Q2 (`DATE_FORMAT` → faixa) | ~111 ms | ~16 ms |
| Q3 (`LIKE '%123'` → prefixo) | ~4,8 ms | ~0,12 ms |

### 1. Maior ganho

Em linhas lidas, o maior ganho foi a Q2: de 199.248 para 5.447 linhas (cerca de 37 vezes menos).
Em tempo absoluto também foi a Q2: de ~111 ms para ~16 ms. A Q3 reescrita tem ganho relativo
parecido em linhas (10.177 para 11), mas o tempo absoluto é pequeno porque a tabela tem só 10 mil
clientes. Percebemos isso no plano pela mudança de `type` de `ALL` (varredura da
tabela inteira) para `range` ou `const`, e pela queda de `rows`. Sem a reescrita, o índice criado
para a data não era usado, porque a função `DATE_FORMAT` na coluna impede o uso do índice.

### 2. Índice existente que não foi usado

- **Q2 original**: existe `idx_locacao_data_retirada`, mas `DATE_FORMAT(data_retirada, ...)` aplica
  uma função na coluna. O MySQL não consegue procurar no índice por um intervalo de valores, então
  faz varredura completa.
- **Q3 original**: `LIKE '%123'` tem curinga no início. Como o índice é ordenado pelo começo do
  nome, o MySQL não sabe onde começar a busca.
- **Q5 com número**: o `cpf` é `UNIQUE`, mas comparar uma coluna de texto com um número faz o MySQL
  converter a coluna para número, e a ordem do índice deixa de valer.

Relação com a busca `LIKE '%modelo%'` da Parte 01, Etapa 4: é a mesma causa, curinga no início.
Ela continua lenta mesmo com índice em `modelo`. Caminhos: um índice `FULLTEXT`, ou uma busca por
prefixo quando o caso de uso permitir.

### 3. Seletividade

- **`status` em `locacoes`** (ativa 24,9%, finalizada 73,1%, cancelada 2,0%): um índice só em
  `status` valeria para `status = 'cancelada'`, que retorna cerca de 2% das linhas. Para
  `finalizada`, o MySQL preferiria a varredura, porque retorna quase tudo. Para `ativa`, 25% ainda
  é alto demais para o índice compensar.
- **`carros.deleted_at`** usado em toda listagem: `deleted_at IS NULL` retorna a grande maioria
  dos carros, então o índice tem baixa seletividade e o otimizador tende a ignorá-lo. Ele seria
  útil para a consulta rara `deleted_at IS NOT NULL` (carros excluídos), ou combinado com outra
  coluna usada no mesmo filtro.

### 4. Custo

Cada índice precisa ser atualizado em todo `INSERT`, `UPDATE` e `DELETE` da tabela. Isso aumenta o
tempo de escrita, o uso de disco e de memória, e o trabalho de log e de bloqueio. Em `Locacao`, cada
inserção também dispara o trigger `trg_locacao_insert`, então o custo de cada índice novo se soma a
ele. Índices demais também confundem o otimizador, que passa a escolher entre mais planos.

O `app_locadora` não consegue criar índice porque `CREATE INDEX` exige o privilégio `INDEX`, que ele
não tem (só `SELECT`, `INSERT` e `UPDATE`). Testado:

```
mysql> CREATE INDEX idx_teste_app ON Cliente (cidade);
ERROR 1142 (42000): INDEX command denied to user 'app_locadora'@'localhost' for table 'Cliente'
```

Índices são mudança de esquema, então entram pelo `admin_locadora`, como todas as migrations.
