# LEIAME — Locadora v2

**Dupla:** Arthur Choi Braga (24101345) e Pedro Emanuel da Costa Madruga (25201037)

O relatório completo, com as evidências, está em [README.md](README.md).

## O que foi feito em cada etapa

| Etapa | Responsável | Resumo |
|---|---|---|
| 0 · Preparação | Os dois | Banco do Bimestre I recriado e conexão conferida. |
| 1 · Estrutura MVC | Arthur | Pastas `config/`, `controllers/`, `models/`, `views/`, `logs/` e `public/`; front controller; CRUD de Carros. |
| 2 · Frontend + Backend | Pedro | Cadastro, listagem, edição e exclusão de Clientes pelo navegador, com mensagens de sucesso e erro. |
| 3 · Backup e recuperação | Arthur | Soft delete em `Veiculo` (`deleted_at`); `mysqldump` e restauração testados com `teste_restore`. |
| 4 · Segurança | Pedro | Prepared statements em todas as consultas, `htmlspecialchars` em toda saída, CSRF e testes de SQL Injection e XSS. |
| 5 · Privilégios | Arthur | Usuários `app_locadora` e `admin_locadora`; a aplicação usa o limitado e o `DELETE` físico é negado. |
| 6 · Autenticação | Pedro | Login com `password_hash`, rotas protegidas, perfis, validação no servidor e log em `logs/erros.log`. |
| 7 · Entrega | Os dois | `backup_locadora.sql`, este LEIAME e o relatório. |

## Teste de SQL Injection

Entrada na busca de carros: `' OR '1'='1`

| Consulta | Resultado |
|---|---|
| Concatenada: `WHERE modelo LIKE '%' OR '1'='1%' AND deleted_at IS NULL` | Retornou **todos** os carros, inclusive o excluído. |
| Prepared statement: `WHERE modelo LIKE :modelo AND deleted_at IS NULL` | Retornou **0** carros. A entrada foi tratada como texto. |

## GRANTs usados

```sql
CREATE USER 'app_locadora'@'localhost' IDENTIFIED BY '...';
GRANT SELECT, INSERT, UPDATE ON locadora.* TO 'app_locadora'@'localhost';

CREATE USER 'admin_locadora'@'localhost' IDENTIFIED BY '...';
GRANT ALL PRIVILEGES ON locadora.* TO 'admin_locadora'@'localhost';

FLUSH PRIVILEGES;
```

As senhas estão em `locadora/database/03_etapa5_privilegios.sql`.
