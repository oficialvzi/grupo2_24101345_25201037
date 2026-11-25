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
