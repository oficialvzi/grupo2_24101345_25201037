# Laboratório 1 (2º Bimestre) — Locadora v2

**Stack:** PHP 8 + MySQL 8.4 (PDO) · padrão MVC · continuação da locadora do Bimestre I
**Status:** Etapas 0 a 7 concluídas

| Integrante | Matrícula |
|---|---|
| Arthur Choi Braga | 24101345 |
| Pedro Emanuel da Costa Madruga | 25201037 |

---

## Divisão do trabalho

| Etapa | Tema | Digitou | Revisou | O que foi feito |
|---|---|---|---|---|
| 0 | Preparação | Os dois | — | Banco do Bimestre I recarregado; conexão MySQL conferida. Encontramos e corrigimos o problema de acentuação (ver abaixo). |
| 1 | Estrutura MVC (Aula 21) | **Arthur** | Pedro | Estrutura de pastas, `config.php`/`database.php`, front controller com rotas, `helpers.php`, CRUD de Carros (`CarroModel`, `CarroController`, views), ajuste de `id` para `AUTO_INCREMENT`. |
| 2 | Frontend + Backend (Aula 20) | **Pedro** | Arthur | Cadastro de Clientes pelo navegador: formulários POST, listagem com total de locações, edição pré-preenchida, mensagens de sucesso/erro, tratamento de CPF duplicado e de cliente com locações. |
| 3 | Backup e recuperação (Aula 22) | **Arthur** | Pedro | Parte A: soft delete em `Veiculo` e view `vw_veiculos_disponiveis` atualizada. Parte B: `mysqldump`, exclusão da `teste_restore` e restauração testada (script `testes/teste_backup_restore.sh`). |
| 4 | Segurança (Aula 23) | **Pedro** | Arthur | Auditoria das consultas (todas com prepared statement), escape com `e()`/`htmlspecialchars`, token CSRF nos POSTs, cabeçalhos de segurança, testes de SQL Injection e XSS. |
| 5 | Privilégios no banco (Aula 24) | **Arthur** | Pedro | Usuários `app_locadora` e `admin_locadora` com `GRANT`, aplicação conectando com o usuário limitado, teste do que cada um pode executar e do `DELETE` físico negado pela aplicação. |
| 6 | Autenticação, validação e erros (Aula 25) | **Pedro** | Arthur | Tabela `usuarios`, login com `password_hash`/`password_verify`, proteção de rotas e perfis, módulo de Locações com validação de datas, validação de placa e e-mail, log em `logs/erros.log`. |
| 7 | Entrega | Os dois | — | Backup final, `LEIAME.md` e relatório com as evidências. |

---

## Estrutura do projeto

```
lab1/
├── locadora/
│   ├── config/
│   │   ├── config.php          # credenciais (único lugar) e parâmetros
│   │   └── database.php        # getConnection(): PDO com ERRMODE_EXCEPTION, sem emulate prepares
│   ├── controllers/            # Carro, Cliente, Locacao, Usuario e Auth (sem SQL)
│   ├── models/                 # Carro, Cliente, Categoria, Filial, Locacao, Usuario (só prepared statements)
│   ├── views/                  # layout/, auth/, carros/, clientes/, locacoes/, usuarios/, erros/
│   ├── core/helpers.php        # e(), url(), redirect(), view(), flash(), CSRF, log e login
│   ├── logs/erros.log          # erros técnicos (nunca exibidos na tela)
│   ├── database/
│   │   ├── setup.sh            # recria o banco: Bimestre I + ajustes da v2
│   │   ├── 01_etapa1_ajustes.sql
│   │   ├── 02_etapa3_soft_delete.sql
│   │   ├── 03_etapa5_privilegios.sql
│   │   ├── 04_etapa6_usuarios.sql
│   │   └── criar_admin.php     # usuários iniciais do sistema
│   ├── backup/backup_locadora.sql
│   └── public/                 # ÚNICA pasta exposta ao navegador
│       ├── index.php           # front controller
│       ├── .htaccess           # reescrita para Apache
│       ├── css/style.css
│       └── js/app.js           # confirmação de exclusão
├── testes/
│   ├── teste_sql_injection.php
│   ├── teste_backup_restore.sh
│   └── teste_privilegios.sh
└── evidencias/                 # prints (.png) e saídas de terminal (.txt)
```

---

## Etapa 0 — Preparação

- O banco foi recriado a partir de `../locadora_final.sql` (script final do Bimestre I).

## Etapa 1 — Estrutura de arquivos (MVC)

- Toda requisição entra por `public/index.php`, que carrega config e helpers, inicia a sessão e despacha para `Controller::método` a partir de uma tabela de rotas (`GET /carros`, `POST /carros/salvar`, …).
- `config/config.php` é o único arquivo com credenciais; `database.php` cria uma conexão PDO reaproveitada.
- **Ajuste no banco (`01_etapa1_ajustes.sql`):** no Bimestre I os `id` de `Veiculo` e `Cliente` eram digitados manualmente. Pelo navegador isso não faz sentido, então passaram a ser `AUTO_INCREMENT`. Como `Locacao` tem FKs para essas colunas, a checagem de FK é desligada só durante o `ALTER` (o tipo `INT` não muda).
- CRUD de Carros: listar (com busca), criar, editar (formulário pré-preenchido) e excluir. Validação no servidor (campos obrigatórios, tamanho, categoria existente, status permitido). Placa duplicada gera mensagem amigável (erro 1062).

| Checklist | Evidência |
|---|---|
| Nenhuma consulta SQL dentro de views | `etapa4_auditoria_codigo.png` |
| Credenciais só em `config/config.php` | `config/config.php` |
| Só `public/` exposta | `e1_08_config_nao_exposto.png`, `etapa4_xss_csrf_headers.png` (404 para `config/`, `models/`, `logs/`) |
| CRUD de Carros pelo MVC | `e1_01` … `e1_07` |

### Evidências

**Figura 1.1 — DESCRIBE antes e depois: id de Veiculo e Cliente passa a ser AUTO_INCREMENT**

![Figura 1.1 — DESCRIBE antes e depois: id de Veiculo e Cliente passa a ser AUTO_INCREMENT](evidencias/etapa1_migracao_banco.png)

**Figura 1.2 — Listagem de carros vinda do banco**

![Figura 1.2 — Listagem de carros vinda do banco](evidencias/e1_01_listagem_carros.png)

**Figura 1.3 — Formulário de cadastro preenchido**

![Figura 1.3 — Formulário de cadastro preenchido](evidencias/e1_02_form_novo_carro.png)

**Figura 1.4 — Mensagem de sucesso e carro novo na lista**

![Figura 1.4 — Mensagem de sucesso e carro novo na lista](evidencias/e1_03_carro_cadastrado.png)

**Figura 1.5 — Formulário de edição pré-preenchido**

![Figura 1.5 — Formulário de edição pré-preenchido](evidencias/e1_04_form_editar_preenchido.png)

**Figura 1.6 — Carro alterado (Onix → Onix Plus, categoria Sedan)**

![Figura 1.6 — Carro alterado (Onix → Onix Plus, categoria Sedan)](evidencias/e1_05_carro_atualizado.png)

**Figura 1.7 — Validação no servidor (com o required do HTML removido)**

![Figura 1.7 — Validação no servidor (com o required do HTML removido)](evidencias/e1_06_validacao_servidor.png)

**Figura 1.8 — Placa duplicada gera mensagem amigável**

![Figura 1.8 — Placa duplicada gera mensagem amigável](evidencias/e1_07_placa_duplicada.png)

**Figura 1.9 — config.php não é acessível pelo navegador**

![Figura 1.9 — config.php não é acessível pelo navegador](evidencias/e1_08_config_nao_exposto.png)

## Etapa 2 — Frontend + Backend (Clientes)

- Formulários enviam por `POST` ao `ClienteController`; a listagem vem de consulta com `LEFT JOIN Locacao` (mostra quantas locações cada cliente tem).
- Mensagem de sucesso ou erro após cada ação (flash na sessão, padrão Post/Redirect/Get).
- Em caso de erro de validação o formulário volta preenchido com o que foi digitado.
- Validações: nome obrigatório, CPF no formato `000.000.000-00`, CPF único (erro 1062).
- Excluir cliente com locações é bloqueado pela FK (erro 1451), e a tela mostra uma mensagem amigável.

| Checklist | Evidência |
|---|---|
| Cadastrar e listar pelo navegador | `e2_01`, `e2_02`, `e2_03` |
| Edição vem preenchida | `e2_04`, `e2_05` |
| Mensagens de erro | `e2_06` (CPF duplicado), `e2_07` (CPF inválido), `e2_08` (cliente com locações) |
| Exclusão | `e2_09` |

### Evidências

**Figura 2.1 — Listagem de clientes com total de locações**

![Figura 2.1 — Listagem de clientes com total de locações](evidencias/e2_01_listagem_clientes.png)

**Figura 2.2 — Formulário de novo cliente**

![Figura 2.2 — Formulário de novo cliente](evidencias/e2_02_form_novo_cliente.png)

**Figura 2.3 — Cliente cadastrado com mensagem de sucesso**

![Figura 2.3 — Cliente cadastrado com mensagem de sucesso](evidencias/e2_03_cliente_cadastrado.png)

**Figura 2.4 — Formulário de edição pré-preenchido**

![Figura 2.4 — Formulário de edição pré-preenchido](evidencias/e2_04_form_editar_preenchido.png)

**Figura 2.5 — Cliente atualizado**

![Figura 2.5 — Cliente atualizado](evidencias/e2_05_cliente_atualizado.png)

**Figura 2.6 — CPF duplicado recusado**

![Figura 2.6 — CPF duplicado recusado](evidencias/e2_06_cpf_duplicado.png)

**Figura 2.7 — CPF em formato inválido recusado**

![Figura 2.7 — CPF em formato inválido recusado](evidencias/e2_07_cpf_invalido.png)

**Figura 2.8 — Cliente com locações não pode ser excluído**

![Figura 2.8 — Cliente com locações não pode ser excluído](evidencias/e2_08_excluir_cliente_com_locacoes.png)

**Figura 2.9 — Cliente sem locações excluído**

![Figura 2.9 — Cliente sem locações excluído](evidencias/e2_09_cliente_excluido.png)

## Etapa 3 — Backup e recuperação

**Parte A — Soft delete** (`02_etapa3_soft_delete.sql`)
- `ALTER TABLE Veiculo ADD COLUMN deleted_at DATETIME NULL DEFAULT NULL;`
- "Excluir" executa `UPDATE Veiculo SET deleted_at = NOW() WHERE id = :id AND deleted_at IS NULL`.
- Todas as consultas de carros filtram `deleted_at IS NULL`, inclusive a view `vw_veiculos_disponiveis` do Bimestre I, que foi recriada.
- Regra extra: um carro com status `locado` não pode ser excluído.
- Como `placa` é `UNIQUE`, um carro excluído continua "ocupando" a placa; a mensagem de duplicidade avisa isso.

**Parte B — Backup e restauração** (`testes/teste_backup_restore.sh`)
1. Criamos `teste_restore` com 2 registros.
2. Fizemos o backup: `mysqldump -u root --default-character-set=utf8mb4 --routines --triggers --databases locadora > locadora/backup/backup_locadora.sql`. Usamos `--routines` porque, sem ele, a procedure `sp_abrir_locacao` e a function `fn_calcula_multa` não entram no dump.
3. Apagamos a tabela com `DROP TABLE teste_restore`; o `SELECT` passou a dar erro 1146.
4. Restauramos com `mysql -u root --default-character-set=utf8mb4 < locadora/backup/backup_locadora.sql`. A tabela, os dados, o carro soft-deleted e os 3 triggers voltaram.

> Usamos `-u root` sem `-p` porque o root local desta máquina não tem senha. Em máquina com senha: `mysqldump -u root -p ...`.

| Checklist | Evidência |
|---|---|
| Carro excluído some da listagem mas continua no banco | `e3_01`, `e3_02`, `etapa3a_soft_delete_banco.png` |
| Arquivo `.sql` de backup e restauração testada | `locadora/backup/backup_locadora.sql`, `etapa3b_backup_restauracao.png` |

### Evidências

**Figura 3.1 — Coluna deleted_at adicionada em Veiculo**

![Figura 3.1 — Coluna deleted_at adicionada em Veiculo](evidencias/etapa3a_migracao_soft_delete.png)

**Figura 3.2 — Listagem antes da exclusão (PQR3S45 visível)**

![Figura 3.2 — Listagem antes da exclusão (PQR3S45 visível)](evidencias/e3_01_antes_soft_delete.png)

**Figura 3.3 — Após excluir, o carro some da listagem**

![Figura 3.3 — Após excluir, o carro some da listagem](evidencias/e3_02_carro_excluido_some_da_lista.png)

**Figura 3.4 — No banco o registro continua, com deleted_at preenchido; a view também o ignora**

![Figura 3.4 — No banco o registro continua, com deleted_at preenchido; a view também o ignora](evidencias/etapa3a_soft_delete_banco.png)

**Figura 3.5 — Carro locado não pode ser excluído**

![Figura 3.5 — Carro locado não pode ser excluído](evidencias/e3_03_carro_locado_nao_exclui.png)

**Figura 3.6 — Backup com mysqldump, DROP da teste_restore e restauração**

![Figura 3.6 — Backup com mysqldump, DROP da teste_restore e restauração](evidencias/etapa3b_backup_restauracao.png)

## Etapa 4 — Segurança

1. **Prepared statements em todas as consultas**: 12 `prepare()` nos models, nenhum `query()`/`exec()` e nenhuma concatenação de variável em SQL. `PDO::ATTR_EMULATE_PREPARES = false` faz o MySQL receber o SQL e os valores separados.
2. **Escape de toda saída**: helper `e()` = `htmlspecialchars($v, ENT_QUOTES, 'UTF-8')`, usado em todo `<?= ?>` das views, inclusive nas mensagens flash e no termo de busca.
3. **Extras de segurança:**
   - Token **CSRF** em todos os formulários POST; sem token, a resposta é HTTP 419 e nada muda.
   - Cabeçalhos `Content-Security-Policy` (bloqueia JS inline), `X-Frame-Options: DENY` e `X-Content-Type-Options: nosniff`.
   - `X-Powered-By` removido; cookie de sessão `HttpOnly` + `SameSite=Lax`.

### Resultado do teste de SQL Injection

Entrada na busca de carros: `' OR '1'='1`

| Forma | SQL que o MySQL executa | Resultado |
|---|---|---|
| **Concatenada** (só em `testes/teste_sql_injection.php`) | `... WHERE modelo LIKE '%' OR '1'='1%' AND deleted_at IS NULL` | **7 linhas**, inclusive o carro **excluído** (PQR3S45). A aspa fecha a string, `modelo LIKE '%'` é verdadeiro para tudo e, pela precedência do `AND` sobre o `OR`, o filtro `deleted_at IS NULL` deixa de valer para a primeira condição. O atacante passa a ver registros que deveriam estar ocultos. |
| **Prepared statement** (aplicação) | `... WHERE modelo LIKE :modelo AND deleted_at IS NULL` com `:modelo = "%' OR '1'='1%"` | **0 linhas**. A entrada é tratada como texto literal: procura um modelo que contenha `' OR '1'='1`. |

**Figura 4.1 — Mesma busca concatenada (7 linhas, vaza o carro excluído) e com prepared statement (0 linhas)**

![Figura 4.1 — Mesma busca concatenada (7 linhas, vaza o carro excluído) e com prepared statement (0 linhas)](evidencias/etapa4_sql_injection.png)

**Figura 4.2 — SQL Injection na busca da aplicação: 0 carros**

![Figura 4.2 — SQL Injection na busca da aplicação: 0 carros](evidencias/e4_01_sqli_busca_prepared.png)

### Resultado do teste de XSS

- Cadastramos um carro com modelo `<script>alert(1)</script>`. A listagem mostra o texto literal e nenhum alerta é disparado. O servidor envia `&lt;script&gt;alert(1)&lt;/script&gt;` (`e4_02`, `e4_03`, `etapa4_xss_csrf_headers.png`).
- Na busca, `<img src=x onerror=alert(2)>` também aparece como texto (`e4_04`).
- O navegador automatizado registrou **0 diálogos** `alert()` durante os testes.

**Figura 4.3 — Cadastro de carro com modelo `<script>alert(1)</script>`**

![Figura 4.3 — Cadastro de carro com modelo script alert(1)](evidencias/e4_02_xss_cadastro.png)

**Figura 4.4 — O script aparece como texto na mensagem e na listagem**

![Figura 4.4 — O script aparece como texto na mensagem e na listagem](evidencias/e4_03_xss_exibido_como_texto.png)

**Figura 4.5 — XSS refletido na busca também é escapado**

![Figura 4.5 — XSS refletido na busca também é escapado](evidencias/e4_04_xss_na_busca.png)

| Checklist | Evidência |
|---|---|
| Nenhum SQL montado por concatenação de entrada | `etapa4_auditoria_codigo.png` |
| `<script>alert(1)</script>` não executa | `e4_03`, `e4_04`, `etapa4_xss_csrf_headers.png` |
| Teste de SQL Injection feito e anotado | `etapa4_sql_injection.png`, tabela acima |

### Evidências

**Figura 4.6 — HTML escapado, POST sem token CSRF recusado (419), cabeçalhos de segurança e pastas protegidas**

![Figura 4.6 — HTML escapado, POST sem token CSRF recusado (419), cabeçalhos de segurança e pastas protegidas](evidencias/etapa4_xss_csrf_headers.png)

**Figura 4.7 — Auditoria do código: nenhum SQL concatenado, nenhum SQL nas views, nenhuma saída sem escape**

![Figura 4.7 — Auditoria do código: nenhum SQL concatenado, nenhum SQL nas views, nenhuma saída sem escape](evidencias/etapa4_auditoria_codigo.png)

## Etapa 5 — Privilégios no banco

- Criamos dois usuários do SGBD (`03_etapa5_privilegios.sql`). Eles são diferentes dos usuários do sistema da tabela `usuarios`.
- `config/config.php` passou a usar `app_locadora`, e a aplicação não conecta mais com `root`.
- Pela aplicação, excluir um cliente executa um `DELETE` físico. O MySQL nega com o erro 1142 e a tela mostra só a mensagem genérica.
- Excluir um carro continua funcionando, porque o soft delete é um `UPDATE`.

```sql
CREATE USER 'app_locadora'@'localhost' IDENTIFIED BY '...';
GRANT SELECT, INSERT, UPDATE ON locadora.* TO 'app_locadora'@'localhost';

CREATE USER 'admin_locadora'@'localhost' IDENTIFIED BY '...';
GRANT ALL PRIVILEGES ON locadora.* TO 'admin_locadora'@'localhost';

FLUSH PRIVILEGES;
```

| Comando | `app_locadora` | `admin_locadora` |
|---|---|---|
| `SELECT` | Permitido | Permitido |
| `INSERT` | Permitido | Permitido |
| `UPDATE` | Permitido | Permitido |
| `DELETE` | Negado (1142) | Permitido |
| `CREATE` / `ALTER` / `DROP` | Negado (1142) | Permitido |
| `GRANT` | Negado (1044) | — |
| Acesso a outro banco (`mysql.user`) | Negado (1142) | Negado (1142) |

| Checklist | Evidência |
|---|---|
| A aplicação conecta com o usuário limitado | `etapa5_conexao_app.png` |
| `DELETE` ou `DROP` com `app_locadora` é negado | `e5_01`, `etapa5_privilegios.png` |

### Evidências

**Figura 5.1 — A aplicação conecta como app_locadora@localhost**

![Figura 5.1 — A aplicação conecta como app_locadora@localhost](evidencias/etapa5_conexao_app.png)

**Figura 5.2 — GRANTs e o que cada usuário do SGBD consegue ou não executar**

![Figura 5.2 — GRANTs e o que cada usuário do SGBD consegue ou não executar](evidencias/etapa5_privilegios.png)

**Figura 5.3 — Excluir cliente pela aplicação: o MySQL nega o DELETE e a tela mostra a mensagem genérica**

![Figura 5.3 — Excluir cliente pela aplicação: o MySQL nega o DELETE e a tela mostra a mensagem genérica](evidencias/e5_01_delete_fisico_negado.png)

**Figura 5.4 — Excluir carro continua funcionando (soft delete é UPDATE)**

![Figura 5.4 — Excluir carro continua funcionando (soft delete é UPDATE)](evidencias/e5_02_soft_delete_continua_funcionando.png)

## Etapa 6 — Autenticação, validação e erros

- Criamos a tabela `usuarios` (`04_etapa6_usuarios.sql`). As senhas são gravadas com `password_hash` e conferidas com `password_verify`.
- No login, `session_regenerate_id(true)` é chamado. E-mail inexistente e senha errada mostram a mesma mensagem: "E-mail ou senha inválidos".
- Todas as rotas, menos `/login`, chamam `exigirLogin()`. Sem login, o usuário é redirecionado para `/login`.
- Perfis: só o `admin` exclui carros e clientes e cadastra usuários. O `atendente` não vê esses botões e é barrado se acessar a rota direto.
- Criamos o módulo de Locações: abrir locação e registrar devolução. Os triggers do Bimestre I mudam o status do carro.
- Validações no servidor:
  - campos obrigatórios;
  - placa no formato `ABC1234` ou `ABC1D23`;
  - e-mail válido (`filter_var`);
  - senha com no mínimo 8 caracteres;
  - data prevista de devolução posterior à retirada;
  - devolução real não anterior à retirada.
- Erros de banco são gravados em `logs/erros.log` com data e detalhe técnico. A tela mostra só "Não foi possível concluir a operação. Tente novamente."

| Checklist | Evidência |
|---|---|
| Senhas com `password_hash` | `etapa6_senhas_hash.png` |
| Listagem sem login redireciona para o login | `e6_01`, `etapa6_rotas_protegidas.png` |
| Dados inválidos recusados pelo servidor | `e6_04`, `e6_06`, `e6_08`, `e6_12`, `e6_14` |
| Erro de banco vai para `logs/erros.log` sem expor detalhes | `e5_01`, `etapa6_log_erros.png` |

### Evidências

**Figura 6.1 — Acessar /carros sem login redireciona para o login**

![Figura 6.1 — Acessar /carros sem login redireciona para o login](evidencias/e6_01_sem_login_redireciona.png)

**Figura 6.2 — Todas as rotas internas respondem 302 para /login**

![Figura 6.2 — Todas as rotas internas respondem 302 para /login](evidencias/etapa6_rotas_protegidas.png)

**Figura 6.3 — Senha errada: "E-mail ou senha inválidos"**

![Figura 6.3 — Senha errada: "E-mail ou senha inválidos"](evidencias/e6_02_login_senha_errada.png)

**Figura 6.4 — E-mail inexistente: a mesma mensagem**

![Figura 6.4 — E-mail inexistente: a mesma mensagem](evidencias/e6_03_login_email_inexistente.png)

**Figura 6.5 — E-mail em formato inválido recusado pelo servidor**

![Figura 6.5 — E-mail em formato inválido recusado pelo servidor](evidencias/e6_04_login_email_invalido.png)

**Figura 6.6 — Login do administrador**

![Figura 6.6 — Login do administrador](evidencias/e6_05_login_admin_ok.png)

**Figura 6.7 — Placa fora do formato recusada**

![Figura 6.7 — Placa fora do formato recusada](evidencias/e6_06_placa_invalida.png)

**Figura 6.8 — Listagem de locações**

![Figura 6.8 — Listagem de locações](evidencias/e6_07_listagem_locacoes.png)

**Figura 6.9 — Data de devolução anterior à retirada recusada**

![Figura 6.9 — Data de devolução anterior à retirada recusada](evidencias/e6_08_locacao_data_invalida.png)

**Figura 6.10 — Formulário corrigido**

![Figura 6.10 — Formulário corrigido](evidencias/e6_09_locacao_form_corrigido.png)

**Figura 6.11 — Locação aberta**

![Figura 6.11 — Locação aberta](evidencias/e6_10_locacao_aberta.png)

**Figura 6.12 — O trigger mudou o carro para locado**

![Figura 6.12 — O trigger mudou o carro para locado](evidencias/e6_11_carro_ficou_locado.png)

**Figura 6.13 — Devolução com data anterior à retirada recusada**

![Figura 6.13 — Devolução com data anterior à retirada recusada](evidencias/e6_12_devolucao_antes_da_retirada.png)

**Figura 6.14 — Devolução registrada**

![Figura 6.14 — Devolução registrada](evidencias/e6_13_devolucao_registrada.png)

**Figura 6.15 — Cadastro de usuário com dados inválidos**

![Figura 6.15 — Cadastro de usuário com dados inválidos](evidencias/e6_14_usuario_dados_invalidos.png)

**Figura 6.16 — Usuário cadastrado**

![Figura 6.16 — Usuário cadastrado](evidencias/e6_15_usuario_cadastrado.png)

**Figura 6.17 — Senhas guardadas como hash na tabela usuarios**

![Figura 6.17 — Senhas guardadas como hash na tabela usuarios](evidencias/etapa6_senhas_hash.png)

**Figura 6.18 — Perfil atendente: sem botão Excluir e sem menu Usuários**

![Figura 6.18 — Perfil atendente: sem botão Excluir e sem menu Usuários](evidencias/e6_16_atendente_sem_excluir.png)

**Figura 6.19 — Atendente barrado ao acessar /usuarios**

![Figura 6.19 — Atendente barrado ao acessar /usuarios](evidencias/e6_17_atendente_sem_acesso_usuarios.png)

**Figura 6.20 — Linha gravada em logs/erros.log pelo DELETE negado**

![Figura 6.20 — Linha gravada em logs/erros.log pelo DELETE negado](evidencias/etapa6_log_erros.png)

**Figura 6.21 — Logout**

![Figura 6.21 — Logout](evidencias/e6_18_logout.png)
